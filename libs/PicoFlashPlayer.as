package {
    import flash.display.Sprite;
    import flash.events.SampleDataEvent;
    import flash.media.Sound;
    import flash.utils.ByteArray;
    import flash.external.ExternalInterface;

    public class PicoFlashPlayer extends Sprite {
        private var _sound:Sound = null;
        private var _dx:Number = 1;
        private var _written:int = 0;
        private var _interleaved:Array = [];
        
        function PicoFlashPlayer() {
            ExternalInterface.addCallback("setup", _setup);
            ExternalInterface.addCallback("currentSampleOffset", _currentSampleOffset);
            ExternalInterface.addCallback("writeAudio", _writeAudio);
        }
        
        private function _setup(channels:int, samplerate:int):void {
            _dx = samplerate / 44100;
        }
        
        private function _currentSampleOffset():int {
            return _written;
        }
        
        private function _writeAudio(interleaved:Array):int {
            if (!_sound) {
                _sound = new Sound();
                _sound.addEventListener(SampleDataEvent.SAMPLE_DATA, _streaming);
                _sound.play();
            }
            
            var i:int, imax:int = interleaved.length, x:Number = 0, written:int = 0;
            
            for (i = 0; i < imax; i += 2) {
                while (x < 1) {
                    _interleaved.push(interleaved[i+0]);
                    _interleaved.push(interleaved[i+1]);
                    x += _dx;
                    written += 1;
                }
                x -= 1;
            }
            
            return written;
        }
        
        private function _streaming(e:SampleDataEvent):void {
            var i:int, buffer:ByteArray = e.data;
            
            if (_interleaved.length < 8192) {
                for (i = 0; i < 8192; ++i) {
                    buffer.writeFloat(0);
                }
                return;
            }
            
            var imax:int = Math.min(_interleaved.length, 16384);
            
            for (i = 0; i < imax; ++i) {
                buffer.writeFloat(_interleaved[i]);
                ++_written;
            }
            
            _interleaved = _interleaved.slice(imax, _interleaved.length);
        }
    }
}
