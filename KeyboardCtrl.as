package {
	import flash.events.*;
	import flash.display.*;
	import flash.ui.Keyboard;



	public class KeyboardCtrl {
		
		var fnctn:Function;
		public function KeyboardCtrl(stage:Stage, _fnctn:Function) {
			
			fnctn = _fnctn;
			stage.addEventListener(KeyboardEvent.KEY_DOWN, myKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, myKeyUp);

		}
	

		function myKeyDown(e: KeyboardEvent): void {
			trace(e.keyCode);
			if (e.keyCode == 49) //1
			{
				fnctn(1);
			}
			if (e.keyCode == 50) //2
			{
				fnctn(2);
			}
			if (e.keyCode == 51) //3
			{
				fnctn(3);
			}
			if (e.keyCode == 52) //4
			{
				fnctn(4);
			}
			if (e.keyCode == 53) //5
			{
				fnctn(5);
			}
			if (e.keyCode == 54) //6
			{
				fnctn(6);
			}
			
		}
		
				

		function myKeyUp(e: KeyboardEvent): void {

			if (e.keyCode == Keyboard.W) {
				
			}
			

		}

	}

}