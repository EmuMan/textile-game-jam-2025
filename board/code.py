import time
import board
import digitalio
import neopixel
from adafruit_ble import BLERadio
from adafruit_ble.advertising.standard import ProvideServicesAdvertisement
from adafruit_ble.services.nordic import UARTService
import adafruit_gps
import busio

class GPSLocation:
    """A simple class to represent a GPS location."""
    def __init__(self, latitude_degrees, latitude_minutes, longitude_degrees, longitude_minutes, fix_quality):
        self.latitude_degrees = latitude_degrees
        self.latitude_minutes = latitude_minutes
        self.longitude_degrees = longitude_degrees
        self.longitude_minutes = longitude_minutes
        self.fix_quality = fix_quality
    
    def __str__(self):
        return f'Lat: {self.latitude_degrees}° {self.latitude_minutes}\' Lon: {self.longitude_degrees}° {self.longitude_minutes}\' Fix: {self.fix_quality}'

class Creature:
    """A class to represent a creature."""
    def __init__(self, creature_id, name, location):
        self.creature_id = creature_id
        self.name = name
        self.location = location

class GameState:
    """A class to hold and manage data relating to the game state."""
    def __init__(self):
        self.tracked = None
        self.last_gps_location = None
    
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
    """Parse and process incoming UART messages."""
    if message.startswith('track:'):
        game.track_from_string(message[6:])
    else:
        print(f'Unknown command: {message}')

def set_leds_during_tracking(game, pixels):
    """Set the LEDs based on the game state."""
    # TODO: Integrate with GPS data to set the LEDs based on the creature's location
    if game.tracked:
        pixels.fill((0, 255, 0))  # Green for tracking
    else:
        pixels.fill((0, 0, 0))    # Off

def flash_leds(pixels, count):
    """Flash the LEDs a specified number of times."""
    for _ in range(count):
        pixels.fill((255, 0, 0))  # Red
        time.sleep(0.1)
        pixels.fill((0, 0, 0))    # Off
        time.sleep(0.1)

def get_gps_data(gps):
    """Get GPS data and return it as a string."""
    if gps.has_fix:
        return GPSLocation(
            gps.latitude_degrees, gps.latitude_minutes,
            gps.longitude_degrees, gps.longitude_minutes,
            gps.fix_quality
        )
    else:
        return None

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
    ble_uart = UARTService()
    ble.name = 'please work'
    advertisement = ProvideServicesAdvertisement(ble_uart)
    advertisement.complete_name = ble.name

    # Set up the GPS module
    gps_uart = busio.UART(board.TX, board.RX, baudrate=9600, timeout=10)
    gps = adafruit_gps.GPS(gps_uart, debug=False)  # Use UART/pyserial
    # Turn on the basic GGA and RMC info
    gps.send_command(b"PMTK314,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
    # Set update rate to twice a second
    gps.send_command(b"PMTK220,500")

    # Advertise until connected
    print('Starting BLE UART...')
    ble.start_advertising(advertisement)

    while not ble.connected:
        pass

    print('BLE connected!')
    
    last_print = time.monotonic()
    while ble.connected:
        gps.update()

        current = time.monotonic()
        if current - last_print >= 1.0:
            last_print = current
            gps_data = get_gps_data(gps)
            if gps_data:
                game.last_gps_location = gps_data
                print(gps_data)

        set_leds_during_tracking(game, pixels)
        
        # TODO: replace button check with a more appropriate method
        # This should run when the creature is captured
        if button_a.value:
            capture_string = game.capture_and_get_string()
            if capture_string:
                ble_uart.write(capture_string.encode())
                print(f'Sent: {capture_string.strip()}')
                flash_leds(pixels, 5)

if __name__ == '__main__':
    main()
