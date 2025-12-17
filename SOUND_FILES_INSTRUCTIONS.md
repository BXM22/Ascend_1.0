# Boxing Sound Files Setup Instructions

## Required Sound Files

The sports timer feature requires two sound files to be added to the Xcode project:

1. **boxing_bell** - Boxing bell sound for round/phase transitions
   - Used when: Round ends, rest ends, timer completes
   - Format: .mp3, .wav, .m4a, .caf, or .aiff

2. **boxing_clap** - Boxing clap sound for 10-second countdown
   - Used when: Timer reaches 10 seconds remaining
   - Format: .mp3, .wav, .m4a, .caf, or .aiff

## Where to Get Sound Files

### Free Resources:
1. **Freesound.org** - Search for "boxing bell" and "boxing clap"
   - https://freesound.org/search/?q=boxing+bell
   - https://freesound.org/search/?q=boxing+clap
   - Make sure to check license (CC0 or CC BY recommended)

2. **Zapsplat** - Professional sound effects library
   - https://www.zapsplat.com
   - Search for "boxing bell" and "boxing clap"

3. **Adobe Stock** - If you have access
   - Search for boxing timer sounds

### Recommended Specifications:
- **Format**: MP3 or WAV (MP3 recommended for smaller file size)
- **Sample Rate**: 44.1 kHz
- **Bit Rate**: 128-192 kbps (for MP3)
- **Duration**: 
  - Bell: 1-2 seconds
  - Clap: 0.5-1 second (will be played multiple times)

## How to Add Sound Files to Xcode

1. **Download the sound files** and name them:
   - `boxing_bell.mp3` (or .wav, .m4a, etc.)
   - `boxing_clap.mp3` (or .wav, .m4a, etc.)

2. **Add to Xcode Project**:
   - Open Xcode
   - Right-click on the `Ascend` folder in the Project Navigator
   - Select "Add Files to 'Ascend'..."
   - Select your sound files
   - **IMPORTANT**: Check "Copy items if needed"
   - **IMPORTANT**: Make sure "Ascend" target is checked
   - Click "Add"

3. **Verify Files are in Bundle**:
   - Select a sound file in Xcode
   - In the File Inspector (right panel), verify:
     - "Target Membership" shows "Ascend" is checked
     - File is listed in the "Copy Bundle Resources" build phase

4. **Test the Sounds**:
   - Build and run the app
   - Start a sports timer
   - When timer reaches 10 seconds, you should hear claps
   - When round/rest ends, you should hear the bell

## Fallback Behavior

If the sound files are not found in the app bundle, the app will automatically fall back to system sounds. The timer will still work, but with less authentic boxing sounds.

## Troubleshooting

- **No sound playing**: 
  - Check that sound is enabled (speaker icon in timer screen)
  - Verify files are in the app bundle (check Target Membership)
  - Check file format is supported (.mp3, .wav, .m4a, .caf, .aiff)
  
- **Sounds not loading**:
  - Make sure file names match exactly: `boxing_bell` and `boxing_clap`
  - Check file extension matches what's in the code
  - Verify files are added to the correct target
