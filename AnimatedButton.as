package  
{
	import flash.display.SimpleButton;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	import flash.events.Event;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;

	public class AnimatedButton extends SimpleButton 
	{
		private var defaultScaleX:Number;
		private var defaultScaleY:Number;

		private var downTweenX:Tween;
		private var downTweenY:Tween;
		private var upTweenX:Tween;
		private var upTweenY:Tween;

		private var isPressed:Boolean = false; // флаг нажатия

		public static const BUTTON_PRESSED:String = "ButtonPressed";

		public function AnimatedButton() 
		{
			super();

			defaultScaleX = this.scaleX;
			defaultScaleY = this.scaleY;

			// Мышь
			this.addEventListener(MouseEvent.MOUSE_DOWN, onPress);
			this.addEventListener(MouseEvent.MOUSE_UP, onRelease);
			this.addEventListener(MouseEvent.ROLL_OUT, onRollOut);

			// Тач
			this.addEventListener(TouchEvent.TOUCH_BEGIN, onPress);
			this.addEventListener(TouchEvent.TOUCH_END, onRelease);
			this.addEventListener(TouchEvent.TOUCH_ROLL_OUT, onRollOut);
		}

		private function onPress(e:Event):void 
		{
			isPressed = true;

			stopTweens();

			downTweenX = new Tween(this, "scaleX", Strong.easeOut, this.scaleX, defaultScaleX * 0.8, 0.2, true);
			downTweenY = new Tween(this, "scaleY", Strong.easeOut, this.scaleY, defaultScaleY * 0.8, 0.2, true);
		}

		private function onRelease(e:Event):void 
		{
			if (!isPressed) return; // если отпустили, но не было нажатия — игнорируем

			isPressed = false;

			stopTweens();

			upTweenX = new Tween(this, "scaleX", Back.easeOut, this.scaleX, defaultScaleX, 0.3, true);
			upTweenY = new Tween(this, "scaleY", Back.easeOut, this.scaleY, defaultScaleY, 0.3, true);

			upTweenY.addEventListener(TweenEvent.MOTION_FINISH, function(evt:TweenEvent):void {
				dispatchEvent(new Event(BUTTON_PRESSED));
			});
		}

		private function onRollOut(e:Event):void 
		{
			if (!isPressed) return; // если мышь не зажата — игнорируем

			isPressed = false; // снимаем флаг, чтобы не вызывать ивент

			stopTweens();

			upTweenX = new Tween(this, "scaleX", Back.easeOut, this.scaleX, defaultScaleX, 0.3, true);
			upTweenY = new Tween(this, "scaleY", Back.easeOut, this.scaleY, defaultScaleY, 0.3, true);

			// НЕ вызываем BUTTON_PRESSED!
		}

		private function stopTweens():void 
		{
			if (downTweenX) { downTweenX.stop(); downTweenX = null; }
			if (downTweenY) { downTweenY.stop(); downTweenY = null; }
			if (upTweenX) { upTweenX.stop(); upTweenX = null; }
			if (upTweenY) { upTweenY.stop(); upTweenY = null; }
		}
	}
}
