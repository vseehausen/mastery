//! Pure Rust MTP implementation for Kindle vocab.db sync
//! No external dependencies beyond rusb

use byteorder::{LittleEndian, ReadBytesExt, WriteBytesExt};
use rusb::{Device, DeviceHandle, GlobalContext};
use std::io::Cursor;
use std::path::Path;
use std::time::Duration;

const KINDLE_VID: u16 = 0x1949;
const TIMEOUT_SHORT: Duration = Duration::from_secs(5);
const TIMEOUT: Duration = Duration::from_secs(20);

const PTP_OC_OPEN_SESSION: u16 = 0x1002;
const PTP_OC_GET_STORAGE_IDS: u16 = 0x1004;
const PTP_OC_GET_OBJECT_HANDLES: u16 = 0x1007;
const PTP_OC_GET_OBJECT_INFO: u16 = 0x1008;
const PTP_OC_GET_OBJECT: u16 = 0x1009;

const PTP_RC_OK: u16 = 0x2001;
const PTP_RC_DEVICE_BUSY: u16 = 0x201D;
const PTP_RC_SESSION_ALREADY_OPEN: u16 = 0x201E;

const PTP_CONTAINER_COMMAND: u16 = 1;
const PTP_CONTAINER_RESPONSE: u16 = 3;

pub struct MtpDevice {
    handle: DeviceHandle<GlobalContext>,
    ep_in: u8,
    ep_out: u8,
    transaction_id: u32,
}

struct ObjectInfo {
    #[allow(dead_code)]
    format: u16,
    filename: String,
    #[allow(dead_code)]
    size: u32,
}

impl MtpDevice {
    pub fn find_kindle() -> Result<Self, String> {
        for device in rusb::devices()
            .map_err(|e| format!("USB error: {}", e))?
            .iter()
        {
            let desc = device.device_descriptor().map_err(|e| format!("{}", e))?;
            if desc.vendor_id() == KINDLE_VID {
                return Self::open_device(device);
            }
        }
        Err("No Kindle device found. Make sure it's connected.".to_string())
    }

    fn open_device(device: Device<GlobalContext>) -> Result<Self, String> {
        let config_desc = device.config_descriptor(0).map_err(|e| format!("{}", e))?;

        let mut ep_in = 0u8;
        let mut ep_out = 0u8;
        let mut interface_num = 0u8;

        for interface in config_desc.interfaces() {
            for desc in interface.descriptors() {
                if desc.class_code() == 6 || desc.class_code() == 0xff {
                    interface_num = desc.interface_number();
                    for endpoint in desc.endpoint_descriptors() {
                        match (endpoint.direction(), endpoint.transfer_type()) {
                            (rusb::Direction::In, rusb::TransferType::Bulk) => {
                                ep_in = endpoint.address()
                            }
                            (rusb::Direction::Out, rusb::TransferType::Bulk) => {
                                ep_out = endpoint.address()
                            }
                            _ => {}
                        }
                    }
                    if ep_in != 0 && ep_out != 0 {
                        break;
                    }
                }
            }
        }

        if ep_in == 0 || ep_out == 0 {
            return Err("Could not find MTP endpoints".to_string());
        }

        let handle = device
            .open()
            .map_err(|e| format!("Failed to open device: {}", e))?;

        // Try to claim interface - if it fails, try to detach kernel driver first
        if let Err(_) = handle.claim_interface(interface_num) {
            // Check if kernel driver is active and try to detach
            if let Ok(true) = handle.kernel_driver_active(interface_num) {
                let _ = handle.detach_kernel_driver(interface_num);
            }
            // Try claiming again - continue anyway if it fails
            let _ = handle.claim_interface(interface_num);
        }

        Ok(Self {
            handle,
            ep_in,
            ep_out,
            transaction_id: 0,
        })
    }

    fn build_command(&mut self, code: u16, params: &[u32]) -> Vec<u8> {
        self.transaction_id += 1;
        let length = 12 + (params.len() * 4) as u32;

        let mut buf = Vec::with_capacity(length as usize);
        buf.write_u32::<LittleEndian>(length).unwrap();
        buf.write_u16::<LittleEndian>(PTP_CONTAINER_COMMAND)
            .unwrap();
        buf.write_u16::<LittleEndian>(code).unwrap();
        buf.write_u32::<LittleEndian>(self.transaction_id).unwrap();
        for param in params {
            buf.write_u32::<LittleEndian>(*param).unwrap();
        }
        buf
    }

    fn send_command(&mut self, code: u16, params: &[u32], timeout: Duration) -> Result<(), String> {
        let cmd = self.build_command(code, params);
        self.handle
            .write_bulk(self.ep_out, &cmd, timeout)
            .map_err(|e| format!("Write failed: {}", e))?;
        Ok(())
    }

    fn read_response(&mut self, timeout: Duration) -> Result<(u16, Vec<u32>), String> {
        let mut buf = vec![0u8; 512];
        let n = self
            .handle
            .read_bulk(self.ep_in, &mut buf, timeout)
            .map_err(|e| format!("Read failed: {}", e))?;

        if n < 12 {
            return Err(format!("Response too short: {} bytes", n));
        }

        let mut cursor = Cursor::new(&buf[..n]);
        let _ = cursor.read_u32::<LittleEndian>().unwrap();
        let _ = cursor.read_u16::<LittleEndian>().unwrap();
        let code = cursor.read_u16::<LittleEndian>().unwrap();
        let _ = cursor.read_u32::<LittleEndian>().unwrap();

        let mut params = Vec::new();
        while cursor.position() + 4 <= n as u64 {
            params.push(cursor.read_u32::<LittleEndian>().unwrap());
        }
        Ok((code, params))
    }

    fn read_data(&mut self) -> Result<Vec<u8>, String> {
        let mut buf = vec![0u8; 64 * 1024];
        let mut all_data = Vec::new();
        let mut expected_len = 0u32;
        let mut first = true;

        loop {
            let n = self
                .handle
                .read_bulk(self.ep_in, &mut buf, TIMEOUT)
                .map_err(|e| format!("Read failed: {}", e))?;

            if n == 0 {
                break;
            }

            if first && n >= 12 {
                let mut cursor = Cursor::new(&buf[..12]);
                expected_len = cursor.read_u32::<LittleEndian>().unwrap();
                let container_type = cursor.read_u16::<LittleEndian>().unwrap();
                if container_type == PTP_CONTAINER_RESPONSE {
                    return Ok(buf[..n].to_vec());
                }
                all_data.extend_from_slice(&buf[12..n]);
                first = false;
            } else {
                all_data.extend_from_slice(&buf[..n]);
            }

            if all_data.len() + 12 >= expected_len as usize {
                break;
            }
        }
        Ok(all_data)
    }

    fn open_session(&mut self) -> Result<(), String> {
        self.send_command(PTP_OC_OPEN_SESSION, &[1], TIMEOUT_SHORT)?;
        let (code, _) = self.read_response(TIMEOUT_SHORT)?;

        match code {
            PTP_RC_OK | PTP_RC_SESSION_ALREADY_OPEN | PTP_RC_DEVICE_BUSY => Ok(()),
            _ => Ok(()), // Proceed anyway, might work
        }
    }

    fn get_storage_ids(&mut self) -> Result<Vec<u32>, String> {
        self.send_command(PTP_OC_GET_STORAGE_IDS, &[], TIMEOUT)?;
        let data = self.read_data()?;
        let (code, _) = self.read_response(TIMEOUT)?;

        if code != PTP_RC_OK {
            return Err(format!("GetStorageIDs failed: {:#06x}", code));
        }
        if data.len() < 4 {
            return Err("No storage data".to_string());
        }

        let mut cursor = Cursor::new(&data);
        let count = cursor.read_u32::<LittleEndian>().unwrap();
        let mut ids = Vec::new();
        for _ in 0..count {
            if cursor.position() + 4 <= data.len() as u64 {
                ids.push(cursor.read_u32::<LittleEndian>().unwrap());
            }
        }
        Ok(ids)
    }

    fn get_object_handles(&mut self, storage_id: u32, parent: u32) -> Result<Vec<u32>, String> {
        self.send_command(PTP_OC_GET_OBJECT_HANDLES, &[storage_id, 0, parent], TIMEOUT)?;
        let data = self.read_data()?;
        let (code, _) = self.read_response(TIMEOUT)?;

        if code != PTP_RC_OK {
            return Err(format!("GetObjectHandles failed: {:#06x}", code));
        }
        if data.len() < 4 {
            return Ok(Vec::new());
        }

        let mut cursor = Cursor::new(&data);
        let count = cursor.read_u32::<LittleEndian>().unwrap();
        let mut handles = Vec::new();
        for _ in 0..count {
            if cursor.position() + 4 <= data.len() as u64 {
                handles.push(cursor.read_u32::<LittleEndian>().unwrap());
            }
        }
        Ok(handles)
    }

    fn get_object_info(&mut self, handle: u32) -> Result<ObjectInfo, String> {
        self.send_command(PTP_OC_GET_OBJECT_INFO, &[handle], TIMEOUT)?;
        let data = self.read_data()?;
        let (code, _) = self.read_response(TIMEOUT)?;

        if code != PTP_RC_OK {
            return Err(format!("GetObjectInfo failed: {:#06x}", code));
        }

        let mut cursor = Cursor::new(&data);
        let _ = cursor.read_u32::<LittleEndian>().unwrap_or(0); // storage_id
        let format = cursor.read_u16::<LittleEndian>().unwrap_or(0);
        let _ = cursor.read_u16::<LittleEndian>().unwrap_or(0); // protection
        let size = cursor.read_u32::<LittleEndian>().unwrap_or(0);

        cursor.set_position(52);
        let filename = self
            .read_ptp_string(&data, 52)
            .unwrap_or_else(|_| "?".to_string());

        Ok(ObjectInfo {
            format,
            filename,
            size,
        })
    }

    fn read_ptp_string(&self, data: &[u8], offset: usize) -> Result<String, String> {
        if offset >= data.len() {
            return Ok(String::new());
        }
        let len = data[offset] as usize;
        if len == 0 {
            return Ok(String::new());
        }

        let mut chars = Vec::with_capacity(len);
        let start = offset + 1;
        for i in 0..len {
            let pos = start + i * 2;
            if pos + 1 >= data.len() {
                break;
            }
            let c = u16::from_le_bytes([data[pos], data[pos + 1]]);
            if c == 0 {
                break;
            }
            chars.push(c);
        }
        String::from_utf16(&chars).map_err(|e| e.to_string())
    }

    fn get_object(&mut self, handle: u32) -> Result<Vec<u8>, String> {
        self.send_command(PTP_OC_GET_OBJECT, &[handle], TIMEOUT)?;

        let mut all_data = Vec::new();
        let mut buf = vec![0u8; 64 * 1024];
        let mut expected_len = 0u32;
        let mut first = true;

        loop {
            let n = self
                .handle
                .read_bulk(self.ep_in, &mut buf, Duration::from_secs(30))
                .map_err(|e| format!("Read failed: {}", e))?;

            if n == 0 {
                break;
            }

            if first && n >= 12 {
                let mut cursor = Cursor::new(&buf[..12]);
                expected_len = cursor.read_u32::<LittleEndian>().unwrap();
                let container_type = cursor.read_u16::<LittleEndian>().unwrap();
                if container_type == PTP_CONTAINER_RESPONSE {
                    break;
                }
                all_data.extend_from_slice(&buf[12..n]);
                first = false;
            } else {
                all_data.extend_from_slice(&buf[..n]);
            }

            if all_data.len() + 12 >= expected_len as usize {
                break;
            }
        }

        let (code, _) = self.read_response(TIMEOUT)?;
        if code != PTP_RC_OK {
            return Err(format!("GetObject failed: {:#06x}", code));
        }

        Ok(all_data)
    }

    fn find_folder(
        &mut self,
        storage_id: u32,
        parent: u32,
        name: &str,
    ) -> Result<Option<u32>, String> {
        let handles = self.get_object_handles(storage_id, parent)?;
        for handle in handles {
            let info = self.get_object_info(handle)?;
            if info.filename.to_lowercase() == name.to_lowercase() {
                return Ok(Some(handle));
            }
        }
        Ok(None)
    }

    /// Downloads vocab.db from Kindle to the specified path
    pub fn download_vocab_db(&mut self, output_path: &Path) -> Result<u64, String> {
        let data = self.read_vocab_db_bytes()?;
        std::fs::write(output_path, &data)
            .map_err(|e| format!("Failed to write file: {}", e))?;
        Ok(data.len() as u64)
    }

    /// Reads vocab.db content from Kindle as bytes
    pub fn read_vocab_db_bytes(&mut self) -> Result<Vec<u8>, String> {
        self.open_session()?;

        let storage_ids = self.get_storage_ids()?;

        for storage_id in storage_ids {
            // Find system folder
            if let Some(system_handle) = self.find_folder(storage_id, 0xFFFFFFFF, "system")? {
                // Find vocabulary folder
                if let Some(vocab_handle) =
                    self.find_folder(storage_id, system_handle, "vocabulary")?
                {
                    // Find vocab.db
                    let handles = self.get_object_handles(storage_id, vocab_handle)?;
                    for handle in handles {
                        let info = self.get_object_info(handle)?;
                        if info.filename.to_lowercase() == "vocab.db" {
                            return self.get_object(handle);
                        }
                    }
                }
            }
        }

        Err("vocab.db not found on Kindle".to_string())
    }
}

/// Sync vocab.db from Kindle via MTP (requires admin privileges)
pub fn sync_vocab_via_mtp(output_path: &Path) -> Result<u64, String> {
    let mut device = MtpDevice::find_kindle()?;
    device.download_vocab_db(output_path)
}

/// Read vocab.db content directly from Kindle via MTP (returns bytes)
#[allow(dead_code)]
pub fn read_vocab_db_via_mtp() -> Result<Vec<u8>, String> {
    let mut device = MtpDevice::find_kindle()?;
    device.read_vocab_db_bytes()
}
