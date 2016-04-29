/*----------------------------------------------------------------------------
 miniAudicle iOS
 iOS GUI to chuck audio programming environment
 
 Copyright (c) 2005-2012 Spencer Salazar.  All rights reserved.
 http://chuck.cs.princeton.edu/
 http://soundlab.cs.princeton.edu/
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
 U.S.A.
 -----------------------------------------------------------------------------*/

#import "mAChucKController.h"

#import "TheAmazingAudioEngine/TheAmazingAudioEngine.h"

#import "miniAudicle.h"
#import "ulib_motion.h"
#import "mAAnalytics.h"
#import "util_buffers.h"

#import <vector>


NSString * const mAAudioInputEnabledPreference = @"audio.input_enabled";
NSString * const mAAudioBufferSizePreference = @"audio.buffer_size";
NSString * const mAAudioAdaptiveBufferingPreference = @"audio.adaptive_buffering";
NSString * const mAAudioBackgroundAudioPreference = @"audio.background_audio";


static mAChucKController * g_chuckController = nil;

@interface mAChucKController ()
{
    std::vector<float> _inputBuffer;
    std::vector<float> _outputBuffer;
    
    BOOL _processAudio;
    
    CircularBuffer<void (^)()> *_audioOperationQueue;
}

@property (strong) AEAudioController *audioController;

- (void)_startVM;
- (void)_startAudioIO;

@end


@implementation mAChucKController

@synthesize ma;

- (void)setEnableInput:(BOOL)enableInput
{
    _enableInput = enableInput;
    
    if(self.audioController)
    {
        NSError *error = NULL;
        [self.audioController setInputEnabled:_enableInput error:&error];
        mAAnalyticsLogError(error);
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:_enableInput forKey:mAAudioInputEnabledPreference];
}

- (void)setBufferSize:(int)bufferSize
{
    _bufferSize = bufferSize;
    [[NSUserDefaults standardUserDefaults] setInteger:_bufferSize forKey:mAAudioBufferSizePreference];
}

- (void)setAdaptiveBuffering:(BOOL)adaptiveBuffering
{
    _adaptiveBuffering = adaptiveBuffering;
    [[NSUserDefaults standardUserDefaults] setBool:_adaptiveBuffering forKey:mAAudioAdaptiveBufferingPreference];
}

- (void)setBackgroundAudio:(BOOL)backgroundAudio
{
    _backgroundAudio = backgroundAudio;
    [[NSUserDefaults standardUserDefaults] setBool:_backgroundAudio forKey:mAAudioBackgroundAudioPreference];
}

+ (void)initialize
{
    if(g_chuckController == nil)
        g_chuckController = [mAChucKController new];
}

+ (mAChucKController *)chuckController
{
    return g_chuckController;
}

- (id)init
{
    if(self = [super init])
    {
        _audioOperationQueue = new CircularBuffer<void (^)()>(32);
        _processAudio = NO;
        
        ma = new miniAudicle;
        
        self.enableInput = [[NSUserDefaults standardUserDefaults] boolForKey:mAAudioInputEnabledPreference];
        self.bufferSize = [[NSUserDefaults standardUserDefaults] integerForKey:mAAudioBufferSizePreference];
        self.adaptiveBuffering = [[NSUserDefaults standardUserDefaults] boolForKey:mAAudioAdaptiveBufferingPreference];
        self.sampleRate = 44100;
        self.backgroundAudio = [[NSUserDefaults standardUserDefaults] boolForKey:mAAudioBackgroundAudioPreference];
    }
    
    return self;
}

- (void)_startVM
{
    ma->set_sample_rate(self.sampleRate);
    ma->set_buffer_size(self.bufferSize);
    
    ma->add_query_func(motion_query);
    
    ma->set_num_inputs(2);
    ma->set_num_outputs(2);
    ma->set_enable_audio(TRUE);
    ma->set_log_level(5);
    ma->set_client_mode(TRUE);
    
    ma->start_vm();
    
    _processAudio = YES;
}

- (void)_startAudioIO
{
    _inputBuffer.resize(self.bufferSize*ma->get_num_inputs());
    _outputBuffer.resize(self.bufferSize*ma->get_num_outputs());
    
    AudioStreamBasicDescription audioDescription;
    memset(&audioDescription, 0, sizeof(audioDescription));
    audioDescription.mFormatID          = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags       = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
    audioDescription.mChannelsPerFrame  = 2;
    audioDescription.mBytesPerPacket    = sizeof(float);
    audioDescription.mFramesPerPacket   = 1;
    audioDescription.mBytesPerFrame     = sizeof(float);
    audioDescription.mBitsPerChannel    = 8 * sizeof(float);
    audioDescription.mSampleRate        = self.sampleRate;
    
    self.audioController = [[AEAudioController alloc] initWithAudioDescription:audioDescription inputEnabled:self.enableInput];
    _audioController.preferredBufferDuration = self.bufferSize/((float) self.sampleRate);
    
    [_audioController addChannels:@[[AEBlockChannel channelWithBlock:^(const AudioTimeStamp *time,
                                                                       UInt32 frames,
                                                                       AudioBufferList *audio) {
        if(_processAudio)
        {
            if(_inputBuffer.size() < frames*ma->get_num_inputs())
            {
                NSLog(@"miniAudicle: warning: input buffer resized in audio I/O process");
                _inputBuffer.resize(frames*ma->get_num_inputs());
            }
            
            if(_outputBuffer.size() < frames*ma->get_num_outputs())
            {
                NSLog(@"miniAudicle: warning: output buffer resized in audio I/O process");
                _outputBuffer.resize(frames*ma->get_num_outputs());
            }
            
            // interleave input
            for(int i = 0; i < frames; i++)
            {
                _inputBuffer[i*2] = ((float*)(audio->mBuffers[0].mData))[i];
                _inputBuffer[i*2+1] = ((float*)(audio->mBuffers[1].mData))[i];
            }
            
            ma->process_audio(frames, _inputBuffer.data(), _outputBuffer.data());
            
            // deinterleave output
            for(int i = 0; i < frames; i++)
            {
                ((float*)(audio->mBuffers[0].mData))[i] = _outputBuffer[i*2];
                ((float*)(audio->mBuffers[1].mData))[i] = _outputBuffer[i*2+1];
            }
        }
        
        void (^audioOperation)();
        while(_audioOperationQueue->get(audioOperation))
            audioOperation();
    }]]];
    
    [_audioController start:NULL];
}

- (void)start
{
    [self _startVM];
    [self _startAudioIO];
}

- (void)restart
{
    // TODO
}

@end
