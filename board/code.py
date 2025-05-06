import time
import random
import math
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
    def __init__(self, latitude, longitude, fix_quality):
        self.latitude = latitude
        self.longitude = longitude
        self.fix_quality = fix_quality
    
    def __str__(self):
        return f'Lat: {self.latitude:.6f}, Lon: {self.longitude:.6f}, Quality: {self.fix_quality}'

    def distance_from(self, other_location):
        # Placeholder for distance calculation
        dist_degrees = ((self.latitude - other_location.latitude) ** 2 + (self.longitude - other_location.longitude) ** 2) ** 0.5
        return dist_degrees * 100000  # Convert to meters (approximation)

def get_random_location(center, max_radius):
    radius = random.uniform(0, max_radius)
    random_angle = random.uniform(0, 2 * 3.14159)  # Random angle in radians
    random_latitude = center.latitude + (radius * 0.00001) * math.cos(random_angle)
    random_longitude = center.longitude + (radius * 0.00001) * math.sin(random_angle)
    # Assuming fix quality of 1 for random locations
    return GPSLocation(random_latitude, random_longitude, 1)

class GameState:
    """A class to hold and manage data relating to the game state."""
    def __init__(self, max_radius=100, catch_radius=10):
        self.last_gps_location = None
        self.creature_gps_location = None
        self.max_radius = max_radius
        self.catch_radius = catch_radius
        self.has_connection = False
    
    def capture(self):
        if self.creature_gps_location:
            # Placeholder for capture logic
            print(f'Creature captured at {self.creature_gps_location}')
            self.creature_gps_location = None
        else:
            print('No creature to capture!')
    
    def get_distance_to_creature(self):
        if self.last_gps_location and self.creature_gps_location:
            return self.last_gps_location.distance_from(self.creature_gps_location)
        return None
    
    def spawn_random_creature(self):
        # Spawn a random creature within a certain radius of the last known location
        if not self.last_gps_location:
            print('No last GPS location to spawn creature from!')
            return
        self.creature_gps_location = get_random_location(self.last_gps_location, self.max_radius)
        print(f'Spawned creature at {self.creature_gps_location}')
    
    def get_distance_percentage(self):
        """Get the distance to the creature as a percentage of the max radius."""
        if self.last_gps_location and self.creature_gps_location:
            distance = self.get_distance_to_creature()
            max_radius = self.max_radius
            min_radius = self.catch_radius
            if distance < min_radius:
                return 1.0 # Can capture
            elif distance > max_radius:
                return 0.0
            else:
                return (max_radius - distance) / (max_radius - min_radius)
        return 0.0
    
    def can_capture(self):
        if self.last_gps_location and self.creature_gps_location:
            distance = self.get_distance_to_creature()
            if distance is not None and distance <= self.catch_radius:
                return True
        return False


def set_leds_during_tracking(game, pixels):
    """Set the LEDs based on the game state."""
    # TODO: Integrate with GPS data to set the LEDs based on the creature's location
    if not game.last_gps_location or not game.creature_gps_location:
        return
    if game.can_capture():
        # Set LEDs to green if the creature can be captured
        pixels.fill((0, 255, 0))
    else:
        distance = game.get_distance_percentage()
        # Set LEDs to a color based on the distance to the creature
        num_lit_leds = int(distance * len(pixels))
        for i in range(len(pixels)):
            if i < num_lit_leds:
                pixels[i] = (255, 255, 0) if game.has_connection else (255, 0, 0)  # Yellow if connected, red if not
            else:
                pixels[i] = (0, 0, 0)
        pixels.show()

def flash_leds(pixels, count, color):
    """Flash the LEDs a specified number of times."""
    for _ in range(count):
        pixels.fill(color)  # Green
        time.sleep(0.1)
        pixels.fill((0, 0, 0))    # Off
        time.sleep(0.1)

def get_gps_data(gps):
    """Get GPS data and return it as a string."""
    if gps.has_fix:
        return GPSLocation(
            gps.latitude_degrees + gps.latitude_minutes / 60,
            gps.longitude_degrees + gps.longitude_minutes / 60,
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

    # Set up the button
    button_b = digitalio.DigitalInOut(board.BUTTON_B)
    button_b.switch_to_input(pull=digitalio.Pull.DOWN)

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
                game.has_connection = True
                print(gps_data)
            else:
                game.has_connection = False
                print('No GPS fix!')

        set_leds_during_tracking(game, pixels)
        
        # TODO: replace button check with a more appropriate method
        # This should run when the creature is captured
        if button_a.value and game.can_capture():
            game.capture()
            ble_uart.write('capture:0')
            print('Creature captured!')
            flash_leds(pixels, 5, (0,255,0))  # Green flash
        
        if button_b.value:
            if game.last_gps_location is None:
                flash_leds(pixels, 2, (255,0,0))  # Red flash
            else:
                # Spawn a random creature
                game.spawn_random_creature()
                flash_leds(pixels, 2, (255,255,0))  # Red flash

if __name__ == '__main__':
    main()
