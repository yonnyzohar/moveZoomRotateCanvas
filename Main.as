package {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Rectangle;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;


	public class Main extends MovieClip {

		var types: Object = {
			direct: 0,
			simpleScale : 1,
			drag: 2,
			scale: 3,
			rotate: 4,
			polygon: 5

		}
		var renderMode: int = types.drag;

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
		var texW:Number = 0;
		var texH:Number = 0;
		var mouseIsDown = false;
		var bitmap = false;

		public function Main() {
			stage.scaleMode = "noScale";
			stage.align = "topLeft";
			stage.addChild(mc);
			texW = monaBd.width;
			texH = monaBd.height;

			Multitouch.inputMode = MultitouchInputMode.GESTURE;
			
			if (renderMode == types.direct) {
				directIMG(0, 0);
			}
			if(renderMode == types.simpleScale){
				directIMGSimpleScale(0, 0, w, h);
			}
			
			if (renderMode == types.drag) {
				stage.addEventListener(Event.ENTER_FRAME, update);
				stage.addEventListener(MouseEvent.MOUSE_DOWN, onDown);
				stage.addEventListener(MouseEvent.MOUSE_UP, onUp);
				directIMGSimpleScale(0, 0, w, h);
			} 
			if (renderMode == types.scale) {
				stage.addEventListener(Event.ENTER_FRAME, update);
				stage.addEventListener(MouseEvent.MOUSE_DOWN, onDown);
				stage.addEventListener(MouseEvent.MOUSE_UP, onUp);
				stage.addEventListener(TransformGestureEvent.GESTURE_ZOOM, scaleObj);
				scaleIMG(0, 0, scale);
			} 
			if (renderMode == types.rotate || renderMode == types.polygon) {
				stage.addEventListener(Event.ENTER_FRAME, update);
				stage.addEventListener(MouseEvent.MOUSE_DOWN, onDown);
				stage.addEventListener(MouseEvent.MOUSE_UP, onUp);
				stage.addEventListener(TransformGestureEvent.GESTURE_ZOOM, scaleObj);
				stage.addEventListener(TransformGestureEvent.GESTURE_ROTATE, rotObj);

				rotateIMG(0, 0, offsetX, offsetY, scale, rot);

			}

			//stage.addEventListener(TransformGestureEvent.GESTURE_PAN, panObj);

		}

		//just draw the source image as is
		function directIMG(_x: Number, _y: Number): void {
			bd.lock();
			bd.fillRect(new Rectangle(0, 0, stage.stageWidth, stage.stageHeight), 0x000000);
			for (var row: Number = Math.max(0, _y * -1); row < texH; row++) {

				for (var col: Number = 0; col < texW; col++) {
					if (col + _x < 0) {
						col -= (col + _x);
						continue;
					}
					if (col + _x > stage.stageWidth) {
						break;
					}
					var pixel = monaBd.getPixel(col, row);
					bd.setPixel(col + _x, row + _y, pixel);
				}

			}
			bd.unlock();
		}
	
		function directIMGSimpleScale(_x: int, _y: int, _w: Number, _h:Number): void {
			bd.lock();
			bd.fillRect(new Rectangle(0, 0, stage.stageWidth, stage.stageHeight), 0x000000);

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
					var pixel = monaBd.getPixel(colPer * texW, rowPer * texH);
					bd.setPixel(col + _x, row + _y, pixel);
				}

			}
			bd.unlock();
		}
	
		//allows scaling at mouse point using offset
		function scaleIMG(_x: int, _y: int, _scale: Number): void {
			var _h = h * _scale;
			var _w = w * _scale;
			bd.lock();
			bd.fillRect(new Rectangle(0, 0, stage.stageWidth, stage.stageHeight), 0x000000);

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
					var pixel = monaBd.getPixel(colPer * texW, rowPer * texH);
					bd.setPixel(col + _x, row + _y, pixel);
				}

			}
			bd.unlock();
		}


		function setOffsetWithInverseRotation(mX: Number, mY: Number): void {
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

		function rotateIMGSimple(_x: Number, _y: Number, _offsetX: Number, _offsetY: Number, _scale: Number, _rot: Number): void {

			//get pivot in global coords
			var pivotX: Number = _x + _offsetX * _scale;
			var pivotY: Number = _y + _offsetY * _scale;
			//this is the size of the square with no rotations
			var p1X: Number = _x;
			var p1Y: Number = _y;

			var p2X: Number = _x + w * _scale;
			var p2Y: Number = _y;

			var p3X: Number = _x;
			var p3Y: Number = _y + h * _scale;

			var p4X: Number = _x + w * _scale;
			var p4Y: Number = _y + h * _scale;

			//distance and angle from pivot to point 1
			var p1InitialAngle: Number = Math.atan2(p1Y - pivotY, p1X - pivotX);
			var p1Magnitude: Number = Math.sqrt((p1X - pivotX) * (p1X - pivotX) + (p1Y - pivotY) * (p1Y - pivotY));

			//distance and angle from pivot to point 2
			var p2InitialAngle: Number = Math.atan2(p2Y - pivotY, p2X - pivotX);
			var p2Magnitude: Number = Math.sqrt((p2X - pivotX) * (p2X - pivotX) + (p2Y - pivotY) * (p2Y - pivotY));

			//distance and angle from pivot to point 3
			var p3InitialAngle: Number = Math.atan2(p3Y - pivotY, p3X - pivotX);
			var p3Magnitude: Number = Math.sqrt((p3X - pivotX) * (p3X - pivotX) + (p3Y - pivotY) * (p3Y - pivotY));

			//distance and angle from pivot to point 4
			var p4InitialAngle: Number = Math.atan2(p4Y - pivotY, p4X - pivotX);
			var p4Magnitude: Number = Math.sqrt((p4X - pivotX) * (p4X - pivotX) + (p4Y - pivotY) * (p4Y - pivotY));

			//new position of point 1 after rotation - save globally, this will be useful when getting the next click
			new1XPos = pivotX + (Math.cos(p1InitialAngle + _rot) * p1Magnitude);
			new1YPos = pivotY + (Math.sin(p1InitialAngle + _rot) * p1Magnitude);

			//new position of point 2 after rotation
			var new2XPos: Number = pivotX + (Math.cos(p2InitialAngle + _rot) * p2Magnitude);
			var new2YPos: Number = pivotY + (Math.sin(p2InitialAngle + _rot) * p2Magnitude);

			//new position of point 3 after rotation
			var new3XPos: Number = pivotX + (Math.cos(p3InitialAngle + _rot) * p3Magnitude);
			var new3YPos: Number = pivotY + (Math.sin(p3InitialAngle + _rot) * p3Magnitude);

			//new position of point 4 after rotation
			var new4XPos: Number = pivotX + (Math.cos(p4InitialAngle + _rot) * p4Magnitude);
			var new4YPos: Number = pivotY + (Math.sin(p4InitialAngle + _rot) * p4Magnitude);

			//this is the distance of colum pixels to iterate over
			var cols: Number = Math.sqrt((new2XPos - new1XPos) * (new2XPos - new1XPos) + (new2YPos - new1YPos) * (new2YPos - new1YPos));
			//this is the distance of row pixles to iterate over
			var rows: Number = Math.sqrt((new3XPos - new1XPos) * (new3XPos - new1XPos) + (new3YPos - new1YPos) * (new3YPos - new1YPos));

			//the angle from left to right
			var colsAngle: Number = (Math.atan2(new2YPos - new1YPos, new2XPos - new1XPos));
			//the angle from top to bottom
			var rowsAngle: Number = (Math.atan2(new3YPos - new1YPos, new3XPos - new1XPos));

			//x and y in columns we need to count
			var cosRowsAngle: Number = Math.cos(rowsAngle);
			var sinRowsAngle: Number = Math.sin(rowsAngle);

			//x and y in rows we need to count
			var cosColsAngle: Number = Math.cos(colsAngle);
			var sinColsAngle: Number = Math.sin(colsAngle);

			bd.lock();
			bd.fillRect(new Rectangle(0, 0, stage.stageWidth, stage.stageHeight), 0x000000);

			for (var row: Number = 0; row < rows; row++) {
				var rowPer: Number = row / rows;
				//the pixel at the beginning of this row
				var sx = new1XPos + cosRowsAngle * (rows * rowPer);
				var sy = new1YPos + sinRowsAngle * (rows * rowPer);


				for (var col: Number = 0; col < cols; col++) {

					var colPer: Number = col / cols;
					//the current pixel in this column
					var px = sx + cosColsAngle * (cols * colPer);
					var py = sy + sinColsAngle * (cols * colPer);

					if (px > 0 && px < stage.stageWidth) {
						if (py > 0 && py < stage.stageHeight) {
							var pixel = monaBd.getPixel(colPer * texW, rowPer * texH);
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
		}


		function rotateImgScanLines(_x: Number, _y: Number, _offsetX: Number, _offsetY: Number, _scale: Number, _rot: Number): void {
			//get pivot in global coords
			var pivotX: Number = _x + _offsetX * _scale;
			var pivotY: Number = _y + _offsetY * _scale;
			//this is the size of the square with no rotations
			var p1X: Number = _x;
			var p1Y: Number = _y;

			var p2X: Number = _x + w * _scale;
			var p2Y: Number = _y;

			var p3X: Number = _x;
			var p3Y: Number = _y + h * _scale;

			var p4X: Number = _x + w * _scale;
			var p4Y: Number = _y + h * _scale;

			var p1: Object = {
				x: p1X,
				y: p1Y,
				u: 0,
				v: 0
			};

			var p2: Object = {
				x: p2X,
				y: p2Y,
				u: 1,
				v: 0
			};

			var p3: Object = {
				x: p3X,
				y: p3Y,
				u: 0,
				v: 1
			};

			var p4: Object = {
				x: p4X,
				y: p4Y,
				u: 1,
				v: 1
			};

			var triangle1: Array = [p1, p2, p4];
			var triangle2: Array = [p3, p1, p4];


			//distance and angle from pivot to point 1
			var p1InitialAngle: Number = Math.atan2(p1Y - pivotY, p1X - pivotX);
			var p1Magnitude: Number = Math.sqrt((p1X - pivotX) * (p1X - pivotX) + (p1Y - pivotY) * (p1Y - pivotY));

			//distance and angle from pivot to point 2
			var p2InitialAngle: Number = Math.atan2(p2Y - pivotY, p2X - pivotX);
			var p2Magnitude: Number = Math.sqrt((p2X - pivotX) * (p2X - pivotX) + (p2Y - pivotY) * (p2Y - pivotY));

			//distance and angle from pivot to point 3
			var p3InitialAngle: Number = Math.atan2(p3Y - pivotY, p3X - pivotX);
			var p3Magnitude: Number = Math.sqrt((p3X - pivotX) * (p3X - pivotX) + (p3Y - pivotY) * (p3Y - pivotY));

			//distance and angle from pivot to point 4
			var p4InitialAngle: Number = Math.atan2(p4Y - pivotY, p4X - pivotX);
			var p4Magnitude: Number = Math.sqrt((p4X - pivotX) * (p4X - pivotX) + (p4Y - pivotY) * (p4Y - pivotY));

			//new position of point 1 after rotation - save globally, this will be useful when getting the next click
			p1.x = pivotX + (Math.cos(p1InitialAngle + _rot) * p1Magnitude);
			p1.y = pivotY + (Math.sin(p1InitialAngle + _rot) * p1Magnitude);
			new1XPos = p1.x;
			new1YPos = p1.y;

			//new position of point 2 after rotation
			p2.x = pivotX + (Math.cos(p2InitialAngle + _rot) * p2Magnitude);
			p2.y = pivotY + (Math.sin(p2InitialAngle + _rot) * p2Magnitude);

			//new position of point 3 after rotation
			p3.x = pivotX + (Math.cos(p3InitialAngle + _rot) * p3Magnitude);
			p3.y = pivotY + (Math.sin(p3InitialAngle + _rot) * p3Magnitude);

			//new position of point 4 after rotation
			p4.x = pivotX + (Math.cos(p4InitialAngle + _rot) * p4Magnitude);
			p4.y = pivotY + (Math.sin(p4InitialAngle + _rot) * p4Magnitude);

			bd.lock();
			bd.fillRect(new Rectangle(0, 0, stage.stageWidth, stage.stageHeight), 0x000000);
			sortPoints(triangle1);
			fillTriangle(triangle1);
			
			sortPoints(triangle2);
			fillTriangle(triangle2);
			bd.unlock();
		}

		//we are going to set the image dimentions with not transformations and only then rotate it
		function rotateIMG(_x: Number, _y: Number, _offsetX: Number, _offsetY: Number, _scale: Number, _rot: Number): void {

			if (renderMode == types.rotate) {
				rotateIMGSimple(_x, _y, _offsetX, _offsetY, _scale, _rot)
			} else {
				rotateImgScanLines(_x, _y, _offsetX, _offsetY, _scale, _rot);
			}
		}


		

		function onDown(e: MouseEvent): void {
			mouseIsDown = true;
			if (renderMode == types.drag) {
				offsetX = (stage.mouseX - prevX);
				offsetY = (stage.mouseY - prevY);
			}
			if (renderMode == types.scale) {
				offsetX = (stage.mouseX - prevX) / scale;
				offsetY = (stage.mouseY - prevY) / scale;
			}
			if (renderMode == types.rotate || renderMode == types.polygon) {
				setOffsetWithInverseRotation(stage.mouseX, stage.mouseY);
			}
		}

		function onUp(e: MouseEvent): void {
			mouseIsDown = false;
		}

		function update(e: Event): void {

			if (mouseIsDown) {
				if (renderMode == types.drag) {
					directIMGSimpleScale(stage.mouseX - offsetX, stage.mouseY - offsetY, w, h);
					prevX = stage.mouseX - offsetX;
					prevY = stage.mouseY - offsetY;
				}
				if (renderMode == types.scale) {
					scaleIMG(stage.mouseX - (offsetX * scale), stage.mouseY - (offsetY * scale), scale);
					prevX = stage.mouseX - (offsetX * scale);
					prevY = stage.mouseY - (offsetY * scale);
				}
				if (renderMode == types.rotate || renderMode == types.polygon) {
					rotateIMG(stage.mouseX - (offsetX * scale), stage.mouseY - (offsetY * scale), offsetX, offsetY, scale, rot);
				}
			}
		}



		function rotObj(e: TransformGestureEvent): void {
			trace("rotate!", e.rotation);
			setOffsetWithInverseRotation(stage.mouseX, stage.mouseY);
			rot += e.rotation / 50;
			rotateIMG(stage.mouseX - offsetX * scale, stage.mouseY - offsetY * scale, offsetX, offsetY, scale, rot);

		}


		function scaleObj(e: TransformGestureEvent): void {
			trace("scale");
			if (renderMode == types.scale) {
				offsetX = (stage.mouseX - prevX) / scale;
				offsetY = (stage.mouseY - prevY) / scale;
			} else if (renderMode == types.rotate || renderMode == types.polygon) {
				setOffsetWithInverseRotation(stage.mouseX, stage.mouseY);
			}

			scale *= e.scaleX;

			if (renderMode == types.scale) {
				scaleIMG(stage.mouseX - offsetX * scale, stage.mouseY - offsetY * scale, scale);
				prevX = stage.mouseX - offsetX * scale;
				prevY = stage.mouseY - offsetY * scale;
			} else if (renderMode == types.rotate || renderMode == types.polygon) {
				rotateIMG(stage.mouseX - offsetX * scale, stage.mouseY - offsetY * scale, offsetX, offsetY, scale, rot);
			}

			/*
			if (bitmap) {
				
			this is for working with a bitmap that you can scale
		
				mc.scaleX = mc.scaleY = scale;
				mc.x = stage.mouseX - offsetX * scale;
				mc.y = stage.mouseY - offsetY * scale;
			} else {
				//this is for actuall drawing pixels!
				
			}*/

		}

		function panObj(e: TransformGestureEvent): void {
			trace("pan");
			//sq.x += e.offsetX * 2;
			//sq.y += e.offsetY * 2;
		}

		/////////----triangle rasterising-----//////
		function sortPoints(points: Array): void {
			var aux: Object;
			//if point 0 is lower than point 1, then point 1 needs to be 0
			if (points[0].y > points[1].y) {
				aux = points[0];
				points[0] = points[1];
				points[1] = aux;
			}
			//if point 0 is lower than point 2, then point 2 needs to be 0
			if (points[0].y > points[2].y) {
				aux = points[0];
				points[0] = points[2];
				points[2] = aux;
			}
			//if point 1 is lower than point 2, then point 2 needs to be 1
			if (points[1].y > points[2].y) {
				aux = points[1];
				points[1] = points[2];
				points[2] = aux;
			}
		}

		function fillTriangle(points:Array): void {
			
			

			var p0x: Number = points[0].x;
			var p0y: Number = points[0].y;

			var p0u: Number = points[0].u;
			var p0v: Number = points[0].v;

			var p1x: Number = points[1].x;
			var p1y: Number = points[1].y;

			var p1u: Number = points[1].u;
			var p1v: Number = points[1].v;

			var p2x: Number = points[2].x;
			var p2y: Number = points[2].y;

			var p2u: Number = points[2].u;
			var p2v: Number = points[2].v;




			//each triangle is split in 2 to make calculations easier.
			//first we do the top part, then the bottom part
			if (p0y < p1y) {


				var side1Width: Number = (p1x - p0x);
				var side1Height: Number = (p1y - p0y);

				//slope from top to first side - when y moves by 1, how much does x move by?
				var slope1: Number = side1Width / side1Height;

				var side2Width: Number = (p2x - p0x);
				var side2Height: Number = (p2y - p0y);
				//slope from top to second side - when y moves by 1, how much does x move by?
				var slope2: Number = side2Width / side2Height;


				//u length - the width of change in percentage on the u (x) axis
				var side1uWidth: Number = (p1u - p0u);
				//v height - the height of change in percentage on the v (y) axis
				var side1vHeight: Number = (p1v - p0v);

				//u length - the width of change in percentage on the u (x) axis
				var side2uWidth: Number = (p2u - p0u);

				//u length - the width of change in percentage on the u (x) axis
				var side2vHeight: Number = (p2v - p0v);

				for (var i: int = 0; i <= side1Height; i++) {

					var _y: Number = p0y + i; // when y grows by 1
					var startX: int = p0x + i * slope1; // start x grows by initial x + (i * slope1)
					var endX: int = p0x + i * slope2; // end x grows by initial x + (i * slope2)

					//u start and v start
					var side1Per: Number = (i / side1Height);
					var startU: Number = p0u + (side1Per * side1uWidth);
					var startV: Number = p0v + (side1Per * side1vHeight);

					//u end and v end
					var side2Per: Number = i / side2Height;
					var endU: Number = p0u + (side2Per * side2uWidth);
					var endV: Number = p0v + (side2Per * side2vHeight);


					//if start is greater than and, swap the,
					if (startX > endX) {
						var aux: Number = startX;
						startX = endX;
						endX = aux;

						//and also swap uv
						aux = startU;
						startU = endU;
						endU = aux;

						aux = startV;
						startV = endV;
						endV = aux;
					}


					if (endX > startX) {

						var triangleCurrWidth: Number = endX - startX;

						//this is the initial u which we will increment
						var u: Number = startU * texW;

						//this is the increment step on the u axis
						var ustep: Number = ((endU - startU) / triangleCurrWidth) * texW;

						//this is the initial v which we will increment
						var v: Number = startV * texH;
						//this is the increment step on the v axis
						var vstep: Number = ((endV - startV) / triangleCurrWidth) * texH;
						
						for (var j: int = 0; j <= triangleCurrWidth; j++) {
							var _x: int = startX + j;

							u += ustep;
							v += vstep;

							var pixel: uint = monaBd.getPixel(u, v);
							bd.setPixel(_x, _y, pixel);
							//g.lineTo(_x, _y);
						}
					}
				}
			}

			////
			//bottom part of the triangle
			if (p1y < p2y) {

				var side3Width: Number = (p2x - p1x);
				var side3Height: Number = (p2y - p1y);
				//slope from top to first side - when y moves by 1, how much does x move by?
				var slope3: Number = side3Width / side3Height;

				var side2Width: Number = (p2x - p0x);
				var side2Height: Number = (p2y - p0y);
				//slope from top to second side - when y moves by 1, how much does x move by?
				var slope2: Number = side2Width / side2Height;

				//this is the middle point on slope 2
				//the slope means - when we move y by 1, how much does x move by?
				//so if we start at the bottom and decrease the side3Height * the slope of side 2 we will get the start point
				var midPointSlope2: Number = p2x - (side3Height * slope2);

				//this is just for drawing the triangle, not part of the algorithm

				//u length - the width of change in percentage on the u (x) axis
				var side3uWidth: Number = (p2u - p1u);
				//v height - the height of change in percentage on the v (y) axis
				var side3vHeight: Number = (p2v - p1v);

				//u length - the width of change in percentage on the u (x) axis
				var side2uWidth: Number = (p2u - p0u);

				//u length - the width of change in percentage on the u (x) axis
				var side2vHeight: Number = (p2v - p0v);

				for (var i: int = 0; i <= side3Height; i++) {
					var startX: int = p1x + i * slope3;
					var endX: int = midPointSlope2 + i * slope2;
					var _y: Number = p1y + i;

					//u start and v start
					var side3Per: Number = (i / side3Height);
					var startU: Number = p1u + (side3Per * side3uWidth);
					var startV: Number = p1v + (side3Per * side3vHeight);

					//u nd and v end
					var side2Per: Number = (_y - p0y) / side2Height;
					var endU: Number = p0u + (side2Per * side2uWidth);
					var endV: Number = p0v + (side2Per * side2vHeight);



					if (startX > endX) {
						var aux: Number = startX;
						startX = endX;
						endX = aux;

						//and also swap uv
						aux = startU;
						startU = endU;
						endU = aux;

						aux = startV;
						startV = endV;
						endV = aux;
					}


					if (endX > startX) {
						var triangleCurrWidth: Number = endX - startX;

						var u: Number = startU * texW;
						//this is the increment on the u axis
						var ustep: Number = ((endU - startU) / triangleCurrWidth) * texW;
						var v: Number = startV * texH;
						//this is the increment on the v axis
						var vstep: Number = ((endV - startV) / triangleCurrWidth) * texH;
						
						
						for (var j: int = 0; j <= triangleCurrWidth; j++) {
							var _x: int = j + startX;
							u += ustep;
							v += vstep;

							var pixel: uint = monaBd.getPixel(u, v);
							bd.setPixel(_x, _y, pixel);
						}
					}
				}

			}
			
		}

	}

}