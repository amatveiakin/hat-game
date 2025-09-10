import os
import subprocess

from midiutil import MIDIFile

track = 0
channel = 0
start_time = 0  # In beats
duration = 1    # In beats
tempo = 600     # In BPM
volume = 100    # 0-127, as per the MIDI standard
max_volume = 127


def newMidi(program):
    midi = MIDIFile(1)  # One track
    midi.addTempo(track, start_time, tempo)
    midi.addProgramChange(track, channel, start_time, program)
    return midi


def generateSoundFile(midi, filepath, fade_start_sec, trim_sec, volume=1.0):
    with open('tmp.midi', 'wb') as output_file:
        midi.writeFile(output_file)
    subprocess.run(['timidity', 'tmp.midi', '-Ow', '-o', 'tmp.wav'],
                   stdout=subprocess.DEVNULL)
    ffmpeg_command = ['ffmpeg', '-y', '-i', 'tmp.wav',
                      '-af', f'volume={volume},afade=out:st={fade_start_sec}:d={trim_sec - fade_start_sec}',
                      '-to', f'{trim_sec}',
                      filepath]
    print(' '.join(ffmpeg_command))
    subprocess.run(ffmpeg_command,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


# C4 major scale: 60, 62, 64, 65, 67, 69, 71, 72
degrees = [
    [60],
    [64],
    [67],
    [72],
    [72, 76, 79],
]
max_combo = len(degrees)

time_over_degrees = [60, 60]
bonus_time_over_degrees = [60]

time_over_program = 28
time_over_volume_coeff = 2.0

for combo in range(0, max_combo):
    midi = newMidi(program=13)
    for note in degrees[combo]:
        midi.addNote(track, channel, note, start_time, duration, volume)
    generateSoundFile(midi,
                      f'word_guessed_combo{combo:01}.ogg',
                      fade_start_sec=0.9,
                      trim_sec=1.0)

midi = newMidi(program=time_over_program)
for time, note in enumerate(time_over_degrees):
    midi.addNote(track, channel, note, time, duration, max_volume)
generateSoundFile(midi,
                  'time_over.ogg',
                  fade_start_sec=0.9,
                  trim_sec=1.0,
                  volume=time_over_volume_coeff)

midi = newMidi(program=time_over_program)
for time, note in enumerate(bonus_time_over_degrees):
    midi.addNote(track, channel, note, time, duration, max_volume)
generateSoundFile(midi,
                  'bonus_time_over.ogg',
                  fade_start_sec=0.9,
                  trim_sec=1.0,
                  volume=time_over_volume_coeff)

os.remove('tmp.midi')
os.remove('tmp.wav')

# Melody test:
#
# beat_len = 10
# midi = MIDIFile(1)  # One track
# midi.addTempo(track, time, tempo)
# midi.addProgramChange(track, channel, time, program)
# for combo in range(0, max_combo):
#     time = combo * beat_len
#     for note in degrees[combo]:
#         midi.addNote(track, channel, note, time, duration, volume)
# turn_end = max_combo * beat_len + 4
# midi.addProgramChange(track, channel, turn_end, end_program)
# for combo in range(0, len(end_degrees)):
#     time = turn_end + combo * 20
#     for note in end_degrees[combo]:
#         midi.addNote(track, channel, note, time, duration, volume)
# with open('tmp.mid', 'wb') as output_file:
#     midi.writeFile(output_file)
# subprocess.run(['timidity', 'tmp.mid'], stdout=subprocess.DEVNULL)

# Program test:
#
# for program in [4, 7, 10, 14, 15, 26, 41, 55, 96, 104, 112, 113, 115, 116]:
# for program in range(0, 128):
#     print(program)
#     midi = MIDIFile(1)
#     midi.addTempo(track, time, tempo)
#     midi.addProgramChange(track, channel, time, program)
#     midi.addNote(track, channel, degrees[0][0], time, duration, volume)
#     with open('tmp.mid', 'wb') as output_file:
#         midi.writeFile(output_file)
#     subprocess.Popen(['timidity', 'tmp.mid'], stdout=subprocess.DEVNULL)
#     sleep(1)

# Candidate programs: 8, 11, 12, 13, 112
# Candidate for 'game over': 4, 7, 10, 14, 15, 26, 41, 55, 96, 104, 112, 113, 115*2, 116
