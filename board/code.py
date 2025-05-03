import time
import board
import digitalio
import neopixel
from adafruit_ble import BLERadio
from adafruit_ble.advertising.standard import ProvideServicesAdvertisement
from adafruit_ble.services.nordic import UARTService

class Creature:
    def __init__(self, creature_id, name, location):
        self.creature_id = creature_id
        self.name = name
        self.location = location

class GameState:
    def __init__(self):
        self.tracked = None
    
    def track_from_string(self, creature_string):
        parts = creature_string.strip().split(':')
        if len(parts) == 3:
            self.tracked = Creature(parts[0], parts[1], parts[2])
            print(f'Tracking {self.tracked.name} at {self.tracked.location}')
        else:
            print('Invalid creature string format')
    
    def capture_and_get_string(self):
        if self.tracked:
            captured_string = f'captured:{self.tracked.creature_id}\n'
            self.tracked = None
            return captured_string
        else:
            return None

def process_uart_message(game, message):
    if message.startswith('track:'):
        game.track_from_string(message[6:])
    else:
        print(f'Unknown command: {message}')

def set_leds_during_tracking(game, pixels):
    if game.tracked:
        pixels.fill((0, 255, 0))  # Green for tracking
    else:
        pixels.fill((0, 0, 0))    # Off

def flash_leds(pixels, count):
    for _ in range(count):
        pixels.fill((255, 0, 0))  # Red
        time.sleep(0.1)
        pixels.fill((0, 0, 0))    # Off
        time.sleep(0.1)

def main():
    # Set up the ring of LEDs
    pixels = neopixel.NeoPixel(board.NEOPIXEL, 10, brightness=0.3, auto_write=True)

    # Set up the button
    button_a = digitalio.DigitalInOut(board.BUTTON_A)
    button_a.switch_to_input(pull=digitalio.Pull.DOWN)

    # Create game
    game = GameState()

    # BLE radio and UART service setup
    ble = BLERadio()
    uart = UARTService()
    ble.name = 'please work'
    advertisement = ProvideServicesAdvertisement(uart)
    advertisement.complete_name = ble.name

    # Advertise until connected
    print('Starting BLE UART...')
    ble.start_advertising(advertisement)

    flash_count = 0

    while True:
        if ble.connected:
            print('BLE connected!')
            while ble.connected:
                set_leds_during_tracking(game, pixels)
                
                # TODO: replace button check with a more appropriate method
                if button_a.value:
                    capture_string = game.capture_and_get_string()
                    if capture_string:
                        uart.write(capture_string.encode())
                        print(f'Sent: {capture_string.strip()}')
                        flash_leds(pixels, 5)

                if uart.in_waiting:
                    # Read incoming messages from UART
                    msg = uart.readline().decode().strip()
                    print(f'Received: {msg}')
                    process_uart_message(game, msg)

if __name__ == '__main__':
    main()
