package {
    import flash.display.MovieClip;
    import flash.display.Loader;
    import flash.net.URLRequest;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.geom.Point;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    public class ClickableImage extends MovieClip {
        private var container:Sprite; // Контейнер для blocker + loader
        private var loader:Loader;

        private var targetPosition:Point; // точка центра экрана локально
        private var marker:Shape;

        private var originalPosition:Point; // изначальная позиция loader (левый верхний угол)
        private var originalScaleX:Number; // изначальный scaleX loader
        private var originalScaleY:Number; // изначальный scaleY loader
        private var isCentered:Boolean = false; // флаг — изображение сейчас в центре?

        private var isAnimating:Boolean = false;
        private var animationTargetX:Number;
        private var animationTargetY:Number;
        private var animationTargetScaleX:Number;
        private var animationTargetScaleY:Number;
        private var animationSpeed:Number = 0.5; // скорость интерполяции (0..1)

        private var blocker:Sprite; // слой блокировки кликов на другие элементы

        public function ClickableImage() {
            super();

            // Создаем контейнер, который будет держать blocker и loader
            container = new Sprite();
            addChild(container);

            // Создаем красный круг-маркер целевой позиции
            marker = new Shape();
            marker.graphics.lineStyle(2, 0xFF0000);
            marker.graphics.drawCircle(0, 0, 10);
            marker.visible = false; // пока скрыт
            addChild(marker);

            // Добавляем слушатель клика на весь объект (на саму ClickableImage)
            this.addEventListener(MouseEvent.CLICK, onClick);
            this.buttonMode = true; // курсор меняется на руку
        }

        // Создаем прозрачный блокирующий слой на весь stage
        private function createBlocker():void {
            blocker = new Sprite();
            blocker.graphics.beginFill(0x000000, 0.5); // полностью прозрачный
            blocker.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
            blocker.graphics.endFill();
            blocker.mouseEnabled = true;
            blocker.mouseChildren = false; // чтобы не пропускать клики по дочерним элементам
            blocker.addEventListener(MouseEvent.CLICK, onBlockerClick);
            trace("[ClickableImage] Блокер создан");
        }

        private function enableBlocker():void {
			if (!blocker) {
				createBlocker();
			}

			if (this.parent && !this.parent.contains(blocker)) {
				this.parent.addChildAt(blocker, this.parent.getChildIndex(this));

				// Устанавливаем глобальные координаты блока, чтобы он накрыл весь stage
				var globalPoint:Point = this.parent.localToGlobal(new Point(0, 0));
				blocker.x = blocker.parent.globalToLocal(new Point(0, 0)).x;
				blocker.y = blocker.parent.globalToLocal(new Point(0, 0)).y;
				
				// или просто:
				blocker.x = -globalPoint.x;
				blocker.y = -globalPoint.y;

				trace("[ClickableImage] Блокер добавлен и позиционирован в родителе");
			}
		}

        private function disableBlocker():void {
            if (blocker && blocker.parent) {
                blocker.removeEventListener(MouseEvent.CLICK, onBlockerClick);
                blocker.parent.removeChild(blocker);
                trace("[ClickableImage] Блокер удалён");
            }
        }

        // Обработчик клика по blocker — просто предотвращает распространение
        private function onBlockerClick(e:MouseEvent):void {
            e.stopPropagation();
            trace("[ClickableImage] Нажатие на блокер");
            // Здесь можно добавить логику, например, закрытие изображения по клику вне его
        }

        public function loadImage(url:String, startX:Number = 0, startY:Number = 0, targetPixelSize:Number = 300):void {
            trace("[ClickableImage] Загрузка изображения: " + url);

            if (loader) {
                if (container.contains(loader)) {
                    container.removeChild(loader);
                }
                loader.unloadAndStop();
                loader = null;
                originalPosition = null;
                originalScaleX = 1;
                originalScaleY = 1;
                isCentered = false;
            }

            loader = new Loader();

            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                onImageLoaded(e, startX, startY, targetPixelSize);
            });

            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onImageError);
            loader.load(new URLRequest(url));
        }

        private function animateTo(targetX:Number, targetY:Number, targetScaleX:Number, targetScaleY:Number):void {
            animationTargetX = targetX;
            animationTargetY = targetY;
            animationTargetScaleX = targetScaleX;
            animationTargetScaleY = targetScaleY;
            if (!isAnimating) {
                isAnimating = true;
                addEventListener(Event.ENTER_FRAME, onAnimate);
            }
        }

        private function onAnimate(e:Event):void {
            loader.x += (animationTargetX - loader.x) * animationSpeed;
            loader.y += (animationTargetY - loader.y) * animationSpeed;
            loader.scaleX += (animationTargetScaleX - loader.scaleX) * animationSpeed;
            loader.scaleY += (animationTargetScaleY - loader.scaleY) * animationSpeed;

            var dx:Number = Math.abs(loader.x - animationTargetX);
            var dy:Number = Math.abs(loader.y - animationTargetY);
            var dsX:Number = Math.abs(loader.scaleX - animationTargetScaleX);
            var dsY:Number = Math.abs(loader.scaleY - animationTargetScaleY);

            if (dx < 0.5 && dy < 0.5 && dsX < 0.01 && dsY < 0.01) {
                loader.x = animationTargetX;
                loader.y = animationTargetY;
                loader.scaleX = animationTargetScaleX;
                loader.scaleY = animationTargetScaleY;
                isAnimating = false;
                removeEventListener(Event.ENTER_FRAME, onAnimate);
                trace("[ClickableImage] Анимация завершена");
            }
        }

        private function onImageLoaded(e:Event, startX:Number, startY:Number, targetPixelSize:Number):void {
            trace("[ClickableImage] Изображение загружено успешно");

            container.addChild(loader);

            var originalWidth:Number = loader.content.width;
            var originalHeight:Number = loader.content.height;

            var maxSide:Number = Math.max(originalWidth, originalHeight);
            var scale:Number = targetPixelSize / maxSide;

            loader.scaleX = scale;
            loader.scaleY = scale;

            var scaledWidth:Number = loader.width;
            var scaledHeight:Number = loader.height;

            // Центрируем изображение по (startX, startY)
            loader.x = startX - scaledWidth / 2;
            loader.y = startY - scaledHeight / 2;

            originalPosition = new Point(loader.x, loader.y);
            originalScaleX = loader.scaleX;
            originalScaleY = loader.scaleY;
            isCentered = false;

            marker.visible = false;

            trace("[ClickableImage] Оригинальная позиция loader (центр): x=" + originalPosition.x + ", y=" + originalPosition.y);
            trace("[ClickableImage] Оригинальный масштаб loader: scaleX=" + originalScaleX + ", scaleY=" + originalScaleY);
        }

        private function onImageError(e:IOErrorEvent):void {
            trace("[ClickableImage] Ошибка загрузки изображения: " + e.text);
        }

        private function onClick(e:MouseEvent):void {
			if (!loader || !originalPosition) {
				trace("[ClickableImage] Клик обработать нельзя — данные не загружены");
				return;
			}

			if (!targetPosition && stage) {
				targetPosition = this.globalToLocal(new Point(stage.stageWidth / 2, stage.stageHeight / 2));
				marker.x = targetPosition.x;
				marker.y = targetPosition.y;
				marker.visible = true;
			}

			if (isAnimating) {
				trace("[ClickableImage] Анимация в процессе — клик игнорируется");
				return;
			}

			if (isCentered) {
				trace("[ClickableImage] Возврат к оригинальной позиции и масштабу");
				moveToOriginal();
				disableBlocker();
			} else {
				trace("[ClickableImage] Перемещение в центр экрана с масштабированием");
				moveToCenter(20); // отступ 50 пикселей сверху и снизу
				enableBlocker();
			}
			isCentered = !isCentered;
		}


        public function moveToCenter(padding:Number = 50):void {
			if (!loader || !targetPosition || !stage) return;

			// Нужно масштабировать так, чтобы высота изображения стала (высота stage - 2 * padding)
			var targetHeight:Number = stage.stageHeight - 2 * padding;
			var scaleY:Number = targetHeight / loader.content.height;

			// При масштабировании по высоте обычно пропорционально масштабируем и по ширине
			// Сохраняем пропорции
			var scaleX:Number = scaleY;

			// Вычисляем новую позицию, чтобы центр изображения совпал с targetPosition
			var newWidth:Number = loader.content.width * scaleX;
			var newHeight:Number = loader.content.height * scaleY;

			var targetX:Number = targetPosition.x - newWidth / 2;
			var targetY:Number = targetPosition.y - newHeight / 2;

			animateTo(targetX, targetY, scaleX, scaleY);

			trace("[ClickableImage] Перемещение в центр с масштабированием по высоте");
		}


        public function moveToOriginal():void {
            if (!loader || !originalPosition) return;

            animateTo(originalPosition.x, originalPosition.y, originalScaleX, originalScaleY);

            trace("[ClickableImage] Возврат к оригинальной позиции и масштабу с анимацией");
        }
    }
}
