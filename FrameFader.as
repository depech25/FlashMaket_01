package {
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.utils.Timer;
    import flash.events.TimerEvent;

    public class FrameFader extends MovieClip {
        public static const CLICKED:String = "FrameFaderClicked";

        private var timer:Timer;
        private var upperFrame:MovieClip;
        private var lowerFrame:MovieClip;

        private var fadeSteps:int = 30;
        private var currentStep:int = 0;
        // Стартуем с флага "выключено", чтобы первый цикл был именно fade-in
        private var fadingIn:Boolean = false;
        private var _stopped:Boolean = false;

        public function FrameFader() {
            addEventListener(Event.ADDED_TO_STAGE, onAdded);
            trace("[FrameFader] Конструктор вызван");
        }

        private function onAdded(e:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, onAdded);
            trace("[FrameFader] onAddedToStage");

            lowerFrame = this.getChildByName("frame1") as MovieClip;
            upperFrame = this.getChildByName("frame2") as MovieClip;

            if (!lowerFrame || !upperFrame) {
                trace("[FrameFader] ❌ Ошибка: нужны два экземпляра с instance names 'frame1' и 'frame2'");
                return;
            }

            lowerFrame.alpha = 1;
            lowerFrame.visible = true;
            trace("[FrameFader] lowerFrame установлен: alpha=1, visible=true");

            upperFrame.alpha = 0;
            upperFrame.visible = true;
            trace("[FrameFader] upperFrame установлен: alpha=0, visible=true");

            this.mouseEnabled = true;
            this.mouseChildren = false;
            addEventListener(MouseEvent.CLICK, onClick);

            timer = new Timer(3000);
            timer.addEventListener(TimerEvent.TIMER, onTimerTick);
            timer.start();
            trace("[FrameFader] Таймер запущен, интервал 3000мс");
        }

        private function onClick(e:MouseEvent):void {
            trace("[FrameFader] CLICK");
            stopAllAnimations();
            // Рассылаем как MouseEvent, чтобы подписчики с сигнатурой MouseEvent не падали
            dispatchEvent(new MouseEvent(CLICKED, true, false, e.localX, e.localY, e.relatedObject, e.ctrlKey, e.altKey, e.shiftKey, e.buttonDown, e.delta));
        }

        private function onTimerTick(e:TimerEvent):void {
            if (_stopped) return;
            currentStep = 0;
            fadingIn = !fadingIn;
            trace("[FrameFader] Таймер сработал. fadingIn = " + fadingIn);

            if (fadingIn) {
                upperFrame.visible = true;
                trace("[FrameFader] upperFrame.visible = true (начинаем показывать)");
            }

            addEventListener(Event.ENTER_FRAME, onFade);
        }

        private function onFade(e:Event):void {
            if (_stopped) {
                removeEventListener(Event.ENTER_FRAME, onFade);
                return;
            }
            currentStep++;
            var progress:Number = currentStep / fadeSteps;

            if (fadingIn) {
                upperFrame.alpha = progress;
                trace("[FrameFader] fade in: step " + currentStep + "/" + fadeSteps + ", alpha=" + upperFrame.alpha.toFixed(2));
            } else {
                upperFrame.alpha = 1 - progress;
                trace("[FrameFader] fade out: step " + currentStep + "/" + fadeSteps + ", alpha=" + upperFrame.alpha.toFixed(2));
            }

            if (currentStep >= fadeSteps) {
                if (!fadingIn) {
                    upperFrame.visible = false;
                    trace("[FrameFader] fade out завершён, upperFrame.visible = false");
                } else {
                    trace("[FrameFader] fade in завершён, upperFrame.visible = true");
                }
                removeEventListener(Event.ENTER_FRAME, onFade);
            }
        }

        private function stopAllAnimations():void {
            _stopped = true;
            if (timer) {
                timer.stop();
                timer.removeEventListener(TimerEvent.TIMER, onTimerTick);
            }
            removeEventListener(Event.ENTER_FRAME, onFade);
            if (upperFrame) {
                upperFrame.alpha = 0;
                upperFrame.visible = false;
            }
            if (lowerFrame) {
                lowerFrame.alpha = 1;
                lowerFrame.visible = true;
            }
            trace("[FrameFader] Animations stopped");
        }
    }
}
