package {
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.display.SimpleButton;
    import flash.events.MouseEvent;
    import flash.events.Event;
    import flash.text.TextField;
    import flash.display.Loader;
    import flash.display.Bitmap;
    import flash.net.URLRequest;
    import flash.events.IOErrorEvent;

    public class ApartmentPopup extends MovieClip {
        public static const CLOSED:String = "ApartmentPopupClosed";
        public var tfNumber:TextField;
        public var tfType:TextField;
        public var tfStatus:TextField;
        public var tfSquare:TextField;
        public var tfArea:TextField;
        public var tfBigText:TextField;

        public var brdr_Image:MovieClip;
        public var btn_ClosePopup:SimpleButton;

        private var imageLoader:Loader;
        private var currentApartmentNumber:String = "";
        private var darkBg:Sprite;

        public function ApartmentPopup() {
            super();
            addEventListener(Event.ADDED_TO_STAGE, onAdded);
        }

        private function onAdded(e:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, onAdded);

            darkBg = new Sprite();
            darkBg.graphics.beginFill(0x000000, 0.5);
            darkBg.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
            darkBg.graphics.endFill();
            darkBg.addEventListener(MouseEvent.CLICK, onBackgroundClick);

            if (parent) parent.addChildAt(darkBg, parent.getChildIndex(this));

            if (btn_ClosePopup) {
                btn_ClosePopup.addEventListener(MouseEvent.CLICK, onCloseClick);
            }

            addEventListener(Event.ENTER_FRAME, onNextFrame);
        }

        private function onNextFrame(e:Event):void {
            removeEventListener(Event.ENTER_FRAME, onNextFrame);

            this.x = (stage.stageWidth  - this.width)  * 0.5;
            this.y = (stage.stageHeight - this.height) * 0.5 + 300;
        }

        private function onBackgroundClick(e:MouseEvent):void {
            closePopup();
        }

        private function onCloseClick(e:MouseEvent):void {
            closePopup();
        }

        private function closePopup():void {
            // Сообщаем подписчикам, что попап закрывается (bubbles=true для ловли на сцене)
            dispatchEvent(new Event(CLOSED, true));
            if (darkBg && darkBg.parent) darkBg.parent.removeChild(darkBg);
            if (parent) parent.removeChild(this);
        }

        public function getCurrentApartmentNumber():String {
            return currentApartmentNumber;
        }

        private function loadImage(url:String):void {
            if (!brdr_Image) return;

            if (imageLoader && imageLoader.parent) {
                imageLoader.parent.removeChild(imageLoader);
            }

            imageLoader = new Loader();
            imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoaded);
            imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onImageError);

            try { imageLoader.load(new URLRequest(url)); } catch (e:*) {}
        }

        private function onImageLoaded(e:Event):void {
            var bmp:Bitmap = imageLoader.content as Bitmap;
            if (!bmp || !bmp.bitmapData) return;

            bmp.smoothing = true;

            var origW:Number = bmp.bitmapData.width;
            var origH:Number = bmp.bitmapData.height;

            var bounds:Object = brdr_Image.getBounds(brdr_Image);
            var frameW:Number = bounds.width;
            var frameH:Number = bounds.height;

            while (brdr_Image.numChildren > 0) {
                brdr_Image.removeChildAt(0);
            }

            brdr_Image.addChild(bmp);

            bmp.scaleX = frameW / origW;
            bmp.scaleY = frameH / origH;

            bmp.x = bounds.x * -1;
            bmp.y = bounds.y * -1;
        }

        private function onImageError(e:IOErrorEvent):void {}

        public function showApartmentInfo(apartmentNumber:String):void {
            currentApartmentNumber = apartmentNumber;

            var type:String     = CRMData.getDataById(apartmentNumber, "type");
            var status:String   = CRMData.getDataById(apartmentNumber, "status");
            var square:*        = CRMData.getDataById(apartmentNumber, "square");
            var imageUrl:String = CRMData.getDataById(apartmentNumber, "base_image");

            // --- Перевод статуса ---
            var statusMap:Object = {
                "Available":        "Доступно",
                "Reserved":         "Забронировано",
                "Occupied":         "Куплено",
                "Сlosed for sale":  "Закрыто к продаже"
            };

            var statusRu:String = statusMap.hasOwnProperty(status) ? statusMap[status] : status;

            // площадь
            var sqNum:Number = Number(square);
            var sqText:String = Math.round(sqNum).toString() + " м²";

            // вывод
            tfType.text   = type ? type : "";
            tfStatus.text = statusRu;
            tfArea.text   = sqText;
            if (tfBigText) {
                tfBigText.text = getTypeDescription(type);
            }

            if (imageUrl) loadImage(imageUrl);
        }

        private function getTypeDescription(type:String):String {
            var desc:Object = {
                "Extency Superior": "Эргономичное пространство резиденции Extency Superior создано с особым вниманием к деталям, где каждая составляющая работает над созданием атмосферы максимального комфорта. Благодаря такому подходу, премиальная резиденция Extency Superior превращается в настоящий оазис спокойствия, где каждая минута отдыха приносит удовольствие, все потребности предугаданы, качество сервиса соответствует высоким стандартам, атмосфера располагает к полноценному отдыху и восстановлению сил. Результатом такого внимания к каждой составляющей становится достижение безупречного баланса между эстетикой и функциональностью.",
                "Emerald": "Премиальная резиденция категории Emerald — это воплощение роскошного комфорта, где каждая деталь тщательно продумана и гармонично сочетается с остальными элементами пространства, уникальность которого определяется изысканным интерьером с тщательно подобранными элементами декора, профессиональной организацией многоуровневого освещения, эргономичной мебелью премиум-класса, продуманным зонированием. Резиденция Emerald представляет собой идеальное воплощение концепции, где дизайн служит не только украшением, но и функциональным решением, пространство организовано, предугадывая потребности, материалы отличаются исключительным качеством, комфорт становится неотъемлемой частью каждой детали. Такое гармоничное сочетание всех компонентов превращает резиденцию в уникальное пространство, где ощущается особенность и окружение заботой.",
                "Family": "Величественная резиденция категории Family раскрывается как изысканная симфония пространства и света. Каждое мгновение, проведенное здесь, наполнено особым очарованием и комфортом. Пространство дышит гармонией: воздушные перспективы открываются через панорамные окна, играя бликами на полированных поверхностях, благородные материалы создают атмосферу утонченной роскоши, плавные линии интерьера сливаются в единый художественный образ, а естественный свет творит волшебство, преображая пространство в течение дня. Резиденция категории Family — настоящая поэма комфорта, где тихие уголки манят уединением, светлые залы приглашают к отдыху, воздушная легкость наполняет каждый сантиметр, изысканная простота создает атмосферу благородства. Подобно произведению искусства, резиденция раскрывает свою красоту постепенно, даря незабываемые впечатления и погружая в мир утонченного комфорта и элегантности. Здесь время течет по-особенному, позволяя насладиться каждым мгновением пребывания в этом удивительном пространстве.",
                "Penthouse": "Императорская резиденция категории Penthouse предстает перед взором как величественный дворец современного искусства, где каждая деталь пронизана духом изысканной роскоши и утонченного вкуса. Божественная гармония пространства раскрывается в симфонии бескрайних видов, растворяющихся в лазурной дали, благородных текстур, мерцающих подобно звездам, изящных изгибов, сплетающихся в неповторимый узор, танцующих лучей, создающих волшебную игру теней. Каждое мгновение в резиденции становится путешествием в мир, где каждая деталь продумана до мелочей, где красота сливается с функциональностью, где царит атмосфера приватности, где роскошь становится естественной."
            };
            return desc.hasOwnProperty(type) ? desc[type] : "";
        }
    }
}
