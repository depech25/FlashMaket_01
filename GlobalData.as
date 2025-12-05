package {
    import ApartmentButtonNew;
    import ApartmentPopup;
    import flash.display.Sprite; 
    
    public class GlobalData {
        public static var CRM:Object = {};
        public static var popup:ApartmentPopup = null;
        public static var activeButton:* = null;

        public static var activeButtonName:String = "";  // <-- Новое свойство для хранения имени кнопки

        public static var apartmentButtons:Array = [];

        public static var activeFloor:String = "";

    }
}

