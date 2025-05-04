use std;
use std::sync::Arc;
use tokio::sync::Mutex;

use btleplug::api::{Central, CentralEvent, CharPropFlags, Characteristic, Manager as _, Peripheral as _, ScanFilter, WriteType};
use btleplug::platform::{Manager, Peripheral};
use godot::prelude::*;
use godot::classes::{ Node, INode };
use godot_tokio::AsyncRuntime;
use futures::stream::StreamExt;

#[derive(Debug, Clone, PartialEq)]
enum BLESignal {
    Connected,
    MessageReceived(String),
}

#[derive(GodotClass)]
#[class(base=Node)]
struct BLEConnection {
    connection: Arc<Mutex<Option<Peripheral>>>,
    tx_characteristic: Arc<Mutex<Option<Characteristic>>>,
    manager: Arc<Mutex<Option<Manager>>>,
    signal_queue: Arc<std::sync::Mutex<Vec<BLESignal>>>,

    base: Base<Node>,
}

#[godot_api]
impl INode for BLEConnection {
    fn init(base: Base<Node>) -> Self {
        godot_print!("Initializing Godot BTLE node..."); // Prints to the Godot console
        Self {
            connection: Arc::new(Mutex::new(None)),
            tx_characteristic: Arc::new(Mutex::new(None)),
            manager: Arc::new(Mutex::new(None)),
            signal_queue: Arc::new(std::sync::Mutex::new(Vec::new())),
            base,
        }
    }
}

#[godot_api]
impl BLEConnection {
    #[func]
    fn initialize(&mut self) {
        godot_print!("Initializing Bluetooth manager...!");
        let manager = self.manager.clone(); // Clone the Arc to use in the async block
        AsyncRuntime::spawn(async move {
            let mut manager = manager.lock().await;
            if manager.is_some() {
                godot_print!("Manager already initialized!");
                return;
            }
            let new_manager = Manager::new().await.unwrap();
            godot_print!("Bluetooth manager initialized!");
            *manager = Some(new_manager);
        });
    }

    #[func]
    fn process_signals(&mut self) {
        let mut signal_queue = self.signal_queue.lock().unwrap().clone();
        while let Some(signal) = signal_queue.pop() {
            godot_print!("Processing signal: {:?}", signal);
            match signal {
                BLESignal::Connected => {
                    self.base_mut().emit_signal("connected", &[]);
                }
                BLESignal::MessageReceived(data) => {
                    self.base_mut().emit_signal("message_received", &[data.to_variant()]);
                }
            }
        }
        self.signal_queue.lock().unwrap().clear(); // Clear the queue in the Arc as well

        let connection = self.connection.clone();
        let signal_queue = self.signal_queue.clone();
        AsyncRuntime::spawn(async move {
            let connection = connection.lock().await;
            if let Some(peripheral) = &*connection {
                peripheral.notifications()
                    .await
                    .unwrap()
                    .for_each(|notification| {
                        let data = String::from_utf8_lossy(&notification.value);
                        godot_print!("Notification: {:?}", data);
                        signal_queue.lock().unwrap().push(BLESignal::MessageReceived(data.to_string()));
                        async {}
                    })
                    .await;
            }
        });
    }

    #[func]
    fn connect_to_device(&mut self, device_id: String) {
        godot_print!("Connection function called: {}", device_id);
        let connection = self.connection.clone();
        let tx_characteristic = self.tx_characteristic.clone();
        let manager = self.manager.clone();
        let signal_queue = self.signal_queue.clone();
        AsyncRuntime::spawn(async move {
            godot_print!("Connecting to device: {}", device_id);
            let manager = manager.lock().await;
            if let Some(manager) = &*manager {
                let adapters = manager.adapters().await.unwrap();
                let central = adapters.into_iter().next().unwrap();
                let central_state = central.adapter_state().await.unwrap();
                godot_print!("Central state: {:?}", central_state);
                let mut events = central.events().await.unwrap();
                central.start_scan(ScanFilter::default()).await.unwrap();

                while let Some(event) = events.next().await {
                    match event {
                        CentralEvent::DeviceDiscovered(id) => {
                            godot_print!("DeviceDiscovered: {:?}", id);
                            let peripheral = central.peripheral(&id).await.unwrap();
                            let properties = peripheral.properties().await.unwrap();
                            let name = properties
                                .and_then(|p| p.local_name)
                                .unwrap_or_else(|| "Unknown".to_string());
                            if name == device_id {
                                godot_print!("Found device: {}", name);
                                central.stop_scan().await.unwrap();
                                
                                peripheral.connect().await.unwrap();
                                godot_print!("Connected to device: {}", name);

                                peripheral.discover_services().await.unwrap();
                                let chars = peripheral.characteristics();
                                for c in &chars {
                                    if c.properties.contains(CharPropFlags::WRITE_WITHOUT_RESPONSE) {
                                        println!("Found writable characteristic");
                                        let mut tx_characteristic = tx_characteristic.lock().await;
                                        *tx_characteristic = Some(c.clone());
                                    } else if c.properties.contains(CharPropFlags::NOTIFY) {
                                        println!("Found notify characteristic");
                                        peripheral.subscribe(c).await.unwrap();
                                    }
                                }

                                let mut connection = connection.lock().await;
                                *connection = Some(peripheral.clone());

                                let mut signal_queue = signal_queue.lock().unwrap();
                                signal_queue.push(BLESignal::Connected);

                                break;
                            }
                        }
                        _ => {}
                    }
                }
            } else {
                godot_warn!("Manager not initialized!");
            };
        });
        godot_print!("Exiting connect function!");
    }

    #[func]
    fn send_message(&self, message: String) {
        let connection = self.connection.clone();
        let tx_characteristic = self.tx_characteristic.clone();
        AsyncRuntime::spawn(async move {
            godot_print!("Sending message: {}", message);
            let connection = connection.lock().await;
            let tx_characteristic = tx_characteristic.lock().await;
            if let Some(peripheral) = &*connection {
                if let Some(characteristic) = &*tx_characteristic {
                    let data = message.as_bytes().to_vec();
                    peripheral.write(characteristic, &data, WriteType::WithoutResponse).await.unwrap();
                    godot_print!("Message sent: {}", message);
                } else {
                    godot_warn!("No writable characteristic found!");
                }
            } else {
                godot_warn!("Not connected to any device!");
            }
        });
    }

    #[signal]
    fn connected();

    #[signal]
    fn disconnected();

    #[signal]
    fn message_received(data: String);
}
