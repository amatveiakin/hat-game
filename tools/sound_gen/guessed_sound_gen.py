import subprocess
from time import sleep

from midiutil import MIDIFile

# C4 major scale: 60, 62, 64, 65, 67, 69, 71, 72
degrees = [
    [60],
    [64],
    [67],
    [72],
    [72, 84],
]
track = 0
channel = 0
time = 0      # In beats
duration = 1  # In beats
tempo = 300   # In BPM
volume = 100  # 0-127, as per the MIDI standard
program = 13
max_combo = len(degrees)

for combo in range(0, max_combo):
    midi = MIDIFile(1)  # One track
    midi.addTempo(track, time, tempo)
    midi.addProgramChange(track, channel, time, program)
    for note in degrees[combo]:
        midi.addNote(track, channel, note, time, duration, volume)
    with open('tmp.mid', 'wb') as output_file:
        midi.writeFile(output_file)
    subprocess.run(['timidity', 'tmp.mid', '-Ow', '-o', 'tmp.wav'],
                   stdout=subprocess.DEVNULL)
    subprocess.run(['ffmpeg', '-y', '-i', 'tmp.wav', '-to', '00:00:01',
                    'guessed_{:02}.ogg'.format(combo)],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# Melody test:
#
# midi = MIDIFile(1)  # One track
# midi.addTempo(track, time, tempo)
# midi.addProgramChange(track, channel, time, program)
# for combo in range(0, max_combo):
#     time = combo * 4
#     for note in degrees[combo]:
#         midi.addNote(track, channel, note, time, duration, volume)
# with open('tmp.mid', 'wb') as output_file:
#     midi.writeFile(output_file)
# subprocess.run(['timidity', 'tmp.mid'], stdout=subprocess.DEVNULL)

# Program test:
#
# for program in range(0, 128):
#     print(program)
#     midi = MIDIFile(1)
#     midi.addTempo(track, time, tempo)
#     midi.addProgramChange(track, channel, time, program)
#     midi.addNote(track, channel, degrees[0], time, duration, volume)
#     with open('tmp.mid', 'wb') as output_file:
#         midi.writeFile(output_file)
#     subprocess.Popen(['timidity', 'tmp.mid'], stdout=subprocess.DEVNULL)
#     sleep(1)

# Candidate programs: 11, 12, 13, 112
# Candidate for 'game over: 119
