package {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Rectangle;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;


	public class Main extends MovieClip {
		var bitmap = false;

		///var bobX = mc.bob.x;
		//var bobY = mc.bob.y;
		var w = 280;
		var h = 400;

		var scale = 1;
		var monaBd: Mona = new Mona();

		var offsetX = w / 2;
		var offsetY = h / 2;
		var prevX = 0;
		var prevY = 0;
		var new1XPos = 0;
		var new1YPos = 0;
		var rot = 0 * Math.PI / 180;
		var bd: BitmapData = new BitmapData(stage.stageWidth, stage.stageHeight, false);
		var mc: Bitmap = new Bitmap(bd);
		var mouseIsDown = false;

		public function Main() {
			stage.scaleMode = "noScale";
			stage.align = "topLeft";
			stage.addChild(mc);
			rotate(0, 0, offsetX, offsetY, scale, rot);

			Multitouch.inputMode = MultitouchInputMode.GESTURE;

			stage.addEventListener(Event.ENTER_FRAME, update);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onUp);
			stage.addEventListener(TransformGestureEvent.GESTURE_ZOOM, scaleObj);
			stage.addEventListener(TransformGestureEvent.GESTURE_PAN, panObj);
			stage.addEventListener(TransformGestureEvent.GESTURE_ROTATE, rotObj);
			// constructor code
		}


		function setOffset(mX: Number, mY: Number): void {
			//whenever we click on the image we want to get the offset from the mouse position to the top left
			//that may be tricky because the image might be rotated
			//we need to rotate the original "top left" point back to origin and then grab its distance from the mouse position
			//otherwise our image will move when we click on it

			//get the angle between mouse pos and rotated top left
			var p1InitialAngle = Math.atan2(mY - new1YPos, mX - new1XPos);
			//get distance between points
			var p1Magnitude = Math.sqrt((new1XPos - mX) * (new1XPos - mX) + (new1YPos - mY) * (new1YPos - mY));
			//rotate the point back to origin by subtracting the current global rotation
			//this is an offest in local coords
			offsetX = Math.cos(p1InitialAngle - rot) * p1Magnitude;
			offsetY = Math.sin(p1InitialAngle - rot) * p1Magnitude;
			//devide by scale to get offset at scale 1
			offsetX /= scale;
			offsetY /= scale;

		}


		function rotate(_x: Number, _y: Number, _offsetX: Number, _offsetY: Number, _scale: Number, _rot: Number): void {
			//get pivot in global coords
			var pivotX = _x + _offsetX * _scale;
			var pivotY = _y + _offsetY * _scale;
			//this is the size of the square with no rotations
			var p1X = _x;
			var p1Y = _y;

			var p2X = _x + w * _scale;
			var p2Y = _y;

			var p3X = _x;
			var p3Y = _y + h * _scale;

			var p4X = _x + w * _scale;
			var p4Y = _y + h * _scale;

			//distance and angle from pivot to point 1
			var p1InitialAngle = Math.atan2(p1Y - pivotY, p1X - pivotX);
			var p1Magnitude = Math.sqrt((p1X - pivotX) * (p1X - pivotX) + (p1Y - pivotY) * (p1Y - pivotY));

			//distance and angle from pivot to point 2
			var p2InitialAngle = Math.atan2(p2Y - pivotY, p2X - pivotX);
			var p2Magnitude = Math.sqrt((p2X - pivotX) * (p2X - pivotX) + (p2Y - pivotY) * (p2Y - pivotY));

			//distance and angle from pivot to point 3
			var p3InitialAngle = Math.atan2(p3Y - pivotY, p3X - pivotX);
			var p3Magnitude = Math.sqrt((p3X - pivotX) * (p3X - pivotX) + (p3Y - pivotY) * (p3Y - pivotY));

			//distance and angle from pivot to point 4
			var p4InitialAngle = Math.atan2(p4Y - pivotY, p4X - pivotX);
			var p4Magnitude = Math.sqrt((p4X - pivotX) * (p4X - pivotX) + (p4Y - pivotY) * (p4Y - pivotY));

			//new position of point 1 after rotation - save globally, this will be useful when getting the next click
			new1XPos = pivotX + (Math.cos(p1InitialAngle + _rot) * p1Magnitude);
			new1YPos = pivotY + (Math.sin(p1InitialAngle + _rot) * p1Magnitude);

			//new position of point 2 after rotation
			var new2XPos = pivotX + (Math.cos(p2InitialAngle + _rot) * p2Magnitude);
			var new2YPos = pivotY + (Math.sin(p2InitialAngle + _rot) * p2Magnitude);

			//new position of point 3 after rotation
			var new3XPos = pivotX + (Math.cos(p3InitialAngle + _rot) * p3Magnitude);
			var new3YPos = pivotY + (Math.sin(p3InitialAngle + _rot) * p3Magnitude);

			//new position of point 4 after rotation
			var new4XPos = pivotX + (Math.cos(p4InitialAngle + _rot) * p4Magnitude);
			var new4YPos = pivotY + (Math.sin(p4InitialAngle + _rot) * p4Magnitude);

			//this is the distance of colum pixels to iterate over
			var cols = Math.sqrt((new2XPos - new1XPos) * (new2XPos - new1XPos) + (new2YPos - new1YPos) * (new2YPos - new1YPos));
			//this is the distance of row pixles to iterate over
			var rows = Math.sqrt((new3XPos - new1XPos) * (new3XPos - new1XPos) + (new3YPos - new1YPos) * (new3YPos - new1YPos));

			//the angle from left to right
			var colsAngle = correctAngle(Math.atan2(new2YPos - new1YPos, new2XPos - new1XPos));
			//the angle from top to bottom
			var rowsAngle = correctAngle(Math.atan2(new3YPos - new1YPos, new3XPos - new1XPos));


			bd.lock();
			bd.fillRect(new Rectangle(0, 0, stage.stageWidth, stage.stageHeight), 0x000000);

			for (var row: Number = 0; row < rows; row++) {
				var rowPer: Number = row / rows;
				//the pixel at the beginning of this row
				var sx = new1XPos + Math.cos(rowsAngle) * (rows * rowPer);
				var sy = new1YPos + Math.sin(rowsAngle) * (rows * rowPer);


				for (var col: Number = 0; col < cols; col++) {

					var colPer: Number = col / cols;
					//the current pixel in this column
					var px = sx + Math.cos(colsAngle) * (cols * colPer);
					var py = sy + Math.sin(colsAngle) * (cols * colPer);
					/*
			if(px < 0)
			{
				var lastX =  Math.cos(colsAngle) * cols;
				var diffX = Math.abs(px);
				var per = diffX / lastX;
				col = cols * per;
			}
		*/


					if (px > 0 && px < stage.stageWidth) {
						if (py > 0 && py < stage.stageHeight) {
							var pixel = monaBd.getPixel(colPer * monaBd.width, rowPer * monaBd.height);
							bd.setPixel(px, py, pixel);
						}
						if (px > stage.stageWidth) {
							break;
						}
						if (py > stage.stageHeight) {
							//break ;//outer;
						}
					}

				}

			}
			bd.unlock();

			//prevX = new1XPos/_scale;
			//prevY = new1YPos/_scale;


		}
		function correctAngle(rad: Number): Number {
			if (rad < 0) {
				//	return Math.PI  - rad;
			}
			return rad;
		}


		function draw(_x: int, _y: int, _scale: Number): void {
			var _h = h * _scale;
			var _w = w * _scale;
			bd.lock();
			bd.fillRect(new Rectangle(0, 0, stage.stageWidth, stage.stageHeight), 0xffffff);

			for (var row: Number = Math.max(0, _y * -1); row < _h; row++) {
				var rowPer: Number = row / _h;

				if (row + _y > stage.stageHeight) {
					break;
				}

				for (var col: Number = 0; col < _w; col++) {
					if (col + _x < 0) {
						col -= (col + _x);
						continue;
					}
					if (col + _x > stage.stageWidth) {
						break;
					}
					var colPer: Number = col / _w;
					var pixel = monaBd.getPixel(colPer * monaBd.width, rowPer * monaBd.height);
					bd.setPixel(col + _x, row + _y, pixel);
				}

			}
			bd.unlock();
		}



		//mc.scaleX = mc.scaleY = scale;




		function onDown(e: MouseEvent): void {
			mouseIsDown = true;
			setOffset(stage.mouseX, stage.mouseY);
			//offsetX = (stage.mouseX - prevX) / scale;
			//offsetY = (stage.mouseY - prevY) / scale;
		}

		function onUp(e: MouseEvent): void {
			mouseIsDown = false;
		}

		function update(e: Event): void {

			//rotate(prevX,prevY,offsetX,offsetY, scale,rot);
			//rot+= 0.01;

			if (mouseIsDown) {

		
				rotate(stage.mouseX - offsetX * scale, stage.mouseY - offsetY * scale, offsetX, offsetY, scale, rot);
					//draw(stage.mouseX - offsetX * scale, stage.mouseY - offsetY * scale, scale);


				//prevX = stage.mouseX - offsetX * scale;
				//prevY = stage.mouseY - offsetY * scale;
			}
		}



		function rotObj(e: TransformGestureEvent): void {
			trace("rotate!", e.rotation);
			//offsetX = (stage.mouseX - prevX) / scale;
			//offsetY = (stage.mouseY - prevY) / scale;
			setOffset(stage.mouseX, stage.mouseY);
			rot += e.rotation / 50;

			rotate(stage.mouseX - offsetX * scale, stage.mouseY - offsetY * scale, offsetX, offsetY, scale, rot);

			//sq.rotation += e.rotation;
		}


		function panObj(e: TransformGestureEvent): void {
			trace("pan");
			//sq.x += e.offsetX * 2;
			//sq.y += e.offsetY * 2;
		}


		function scaleObj(e: TransformGestureEvent): void {
			trace("scale");
			setOffset(stage.mouseX, stage.mouseY);

			//offsetX = (stage.mouseX - prevX) / scale;
			//offsetY = (stage.mouseY - prevY) / scale;
			scale *= e.scaleX;

			if (bitmap) {
				/*
			this is for working with a bitmap that you can scale
		*/
				mc.scaleX = mc.scaleY = scale;
				mc.x = stage.mouseX - offsetX * scale;
				mc.y = stage.mouseY - offsetY * scale;
			} else {
				//this is for actuall drawing pixels!
				//draw(stage.mouseX - offsetX * scale, stage.mouseY - offsetY * scale, scale);
				rotate(stage.mouseX - offsetX * scale, stage.mouseY - offsetY * scale, offsetX, offsetY, scale, rot);
			}

			prevX = stage.mouseX - offsetX * scale;
			prevY = stage.mouseY - offsetY * scale;




		}

	}

}












//draw(0, 0, 1);