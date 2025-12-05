package  
{
    import flash.display.SimpleButton;
    import flash.display.Sprite;
    import flash.display.Loader;
    import flash.events.MouseEvent;
    import flash.net.URLRequest;
    import flash.events.Event;
    
    public class ShowApartmentPhotos extends SimpleButton 
    {
        private var photoUrls:Array = [];
        
        private var currentIndex:int = 0;
        private var container:Sprite;
        private var loader:Loader;
        
        public function ShowApartmentPhotos() 
        {
            super();
            this.addEventListener(MouseEvent.CLICK, onClick);
        }
        
        private function onClick(e:MouseEvent):void 
        {
            var last4:String = "";
            
            if (GlobalData.activeButtonName != null && GlobalData.activeButtonName.length >= 4)
            {
                last4 = GlobalData.activeButtonName.substr(-4);
                trace("Последние 4 символа имени кнопки: " + last4);
                trace("Полное имя кнопки из GlobalData.activeButtonName: " + GlobalData.activeButtonName);
                
                // Получаем массив изображений из CRMData
                var raw:* = CRMData.getDataById(last4, "render");

                if (raw is String) {
                    photoUrls = [raw];                 // один URL → массив
                }
                else if (raw is Array) {
                    photoUrls = raw;                   // массив URL
                }
                else {
                    photoUrls = [];                    // ничего не найдено
                }

                trace("Массив изображений:", photoUrls);

                if (photoUrls.length == 0) {
                    trace("Нет изображений для данного ID");
                    return;
                }

                trace("Массив изображений из CRMData:");
                trace(photoUrls);
                
                if (photoUrls == null || photoUrls.length == 0) {
                    trace("Нет изображений для данного ID");
                    return; // не открываем просмотр
                }
                
                currentIndex = 0;
                openPhotoViewer();
            }
            else
            {
                trace("Активная кнопка не выбрана или имя слишком короткое");
            }
        }
        
        private function openPhotoViewer():void
        {
            container = new Sprite();
            container.graphics.beginFill(0x000000, 0.8);
            container.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
            container.graphics.endFill();
            stage.addChild(container);
            
            loader = new Loader();
            container.addChild(loader);
            
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, centerPhoto);

            // 🔥 Если в массиве больше 1 картинки — добавляем переключение
            if (photoUrls.length > 1) {
                loader.addEventListener(MouseEvent.CLICK, onNextPhoto);
            }

            container.addEventListener(MouseEvent.CLICK, onCloseViewer);
            
            loadPhoto(currentIndex);
        }

				
        private function loadPhoto(index:int):void
		{
			if (index >= 0 && index < photoUrls.length) {
				// Перед загрузкой нового фото снимаем старый слушатель COMPLETE,
				// чтобы избежать дублирования и ошибки
				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, centerPhoto);
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, centerPhoto);
				
				loader.load(new URLRequest(photoUrls[index]));
			}
		}

        
        private function centerPhoto(e:Event):void
		{
			// Проверяем, что loader не null и stage существует
			if (!loader || !stage) return;
			
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, centerPhoto);
			
			// Центрируем
			loader.x = (stage.stageWidth - loader.width) / 2;
			loader.y = (stage.stageHeight - loader.height) / 2;
		}
        private function onNextPhoto(e:MouseEvent):void
        {
            e.stopPropagation();
            
            currentIndex++;
            if (currentIndex >= photoUrls.length) {
                currentIndex = 0;
            }
            loadPhoto(currentIndex);
        }
        
        private function onCloseViewer(e:MouseEvent):void
        {
            stage.removeChild(container);
            container = null;
            loader = null;
            currentIndex = 0;
        }
    }
}
