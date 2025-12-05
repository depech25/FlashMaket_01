package  
{
    import flash.display.SimpleButton;
    import flash.display.Sprite;
    import flash.display.Loader;
    import flash.events.MouseEvent;
    import flash.net.URLRequest;
    import flash.events.Event;
    
    public class ShowApartmentPlans extends SimpleButton 
    {
        private var planUrls:Array = [];
        
        private var currentIndex:int = 0;
        private var container:Sprite;
        private var loader:Loader;
        
        public function ShowApartmentPlans() 
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
                
                // Получаем поле "plan" из CRMData
                var raw:* = CRMData.getDataById(last4, "plan");

                if (raw is String) {
                    planUrls = [raw];  // один URL → массив
                }
                else if (raw is Array) {
                    planUrls = raw;    // массив URL
                }
                else {
                    planUrls = [];     // ничего не найдено
                }

                trace("Массив планов:", planUrls);

                if (planUrls.length == 0) {
                    trace("Нет планов для данного ID");
                    return;
                }
                
                currentIndex = 0;
                openPlanViewer();
            }
            else
            {
                trace("Активная кнопка не выбрана или имя слишком короткое");
            }
        }
        
        private function openPlanViewer():void
        {
            container = new Sprite();
            container.graphics.beginFill(0x000000, 0.8);
            container.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
            container.graphics.endFill();
            stage.addChild(container);
            
            loader = new Loader();
            container.addChild(loader);
            
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, centerPlan);

            // 🔥 Если изображение одно — не переключаем
            if (planUrls.length > 1) {
                loader.addEventListener(MouseEvent.CLICK, onNextPlan);
            }

            container.addEventListener(MouseEvent.CLICK, onCloseViewer);
            
            loadPlan(currentIndex);
        }

        
        private function loadPlan(index:int):void
        {
            if (index >= 0 && index < planUrls.length) {
                
                loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, centerPlan);
                loader.contentLoaderInfo.addEventListener(Event.COMPLETE, centerPlan);
                
                loader.load(new URLRequest(planUrls[index]));
            }
        }

        private function centerPlan(e:Event):void
        {
            if (!loader || !stage) return;
            
            loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, centerPlan);
            
            loader.x = (stage.stageWidth - loader.width) / 2;
            loader.y = (stage.stageHeight - loader.height) / 2;
        }

        private function onNextPlan(e:MouseEvent):void
        {
            e.stopPropagation();
            
            currentIndex++;
            if (currentIndex >= planUrls.length) {
                currentIndex = 0;
            }
            loadPlan(currentIndex);
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
