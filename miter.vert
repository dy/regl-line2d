precision highp float;

attribute vec2 aCoord, bCoord, nextCoord, prevCoord;
attribute vec4 aColor, bColor;
attribute float lineEnd, lineTop;

uniform vec2 scale, translate;
uniform float thickness, pixelRatio;
uniform vec4 viewport;
uniform float miterLimit, dashLength;

varying vec4 fragColor;
varying vec4 startCutoff, endCutoff;
varying vec2 tangent;

const float REVERSE_MITER = -1e-5;

void main() {
	vec2 aCoord = aCoord, bCoord = bCoord, prevCoord = prevCoord, nextCoord = nextCoord;
	vec2 scaleRatio = scale * viewport.zw;

	float lineStart = 1. - lineEnd;
	float lineBot = 1. - lineTop;

	vec2 normalWidth = pixelRatio * thickness / viewport.zw;

	vec2 prevDiff = aCoord - prevCoord;
	vec2 currDiff = bCoord - aCoord;
	vec2 nextDiff = nextCoord - bCoord;

	vec2 prevDirection = normalize(prevDiff);
	vec2 currDirection = normalize(currDiff);
	vec2 nextDirection = normalize(nextDiff);

	if (dot(currDirection, nextDirection) == -1.) {
		nextCoord = bCoord;
		nextDiff = nextCoord - bCoord;
	}
	if (dot(currDirection, prevDirection) == -1.) {
		if (length(currDiff) <= length(prevDiff)) {
			return;
		}
		aCoord = prevCoord;
		currDiff = bCoord - aCoord;
	}

	vec2 prevTangent = normalize(prevDiff * scaleRatio);
	vec2 currTangent = normalize(currDiff * scaleRatio);
	vec2 nextTangent = normalize(nextDiff * scaleRatio);

	vec2 prevNormal = vec2(-prevTangent.y, prevTangent.x);
	vec2 currNormal = vec2(-currTangent.y, currTangent.x);
	vec2 nextNormal = vec2(-nextTangent.y, nextTangent.x);

	vec2 startJoinNormal = normalize(prevTangent - currTangent);
	vec2 endJoinNormal = normalize(currTangent - nextTangent);

	if (prevDirection == currDirection) {
		startJoinNormal = currNormal;
	}
	if (nextDirection == currDirection) {
		endJoinNormal = currNormal;
	}
	if (prevCoord == aCoord) {
		startJoinNormal = currNormal;
	}
	if (aCoord == bCoord) {
		endJoinNormal = startJoinNormal;
	}
	if (bCoord == nextCoord) {
		endJoinNormal = currNormal;
	}

	float startJoinShift = dot(currNormal, startJoinNormal);
	float endJoinShift = dot(currNormal, endJoinNormal);

	float startMiterRatio = abs(1. / startJoinShift);
	float endMiterRatio = abs(1. / endJoinShift);

	vec2 startJoin = startJoinNormal * startMiterRatio;
	vec2 endJoin = endJoinNormal * endMiterRatio;

	vec2 startTopJoin, startBottomJoin, endTopJoin, endBottomJoin;
	startTopJoin = sign(startJoinShift) * startJoin * .5;
	startBottomJoin = -startTopJoin;

	endTopJoin = sign(endJoinShift) * endJoin * .5;
	endBottomJoin = -endTopJoin;

	//TODO: reduce inter-miter join length to min between distances
	//TODO: shift inter-miter joins to avoid overlaps

	vec2 aPosition = (aCoord + translate) * scale;
	vec2 aTopPosition = aPosition + normalWidth * startTopJoin;
	vec2 aBotPosition = aPosition + normalWidth * startBottomJoin;

	vec2 bPosition = (bCoord + translate) * scale;
	vec2 bTopPosition = bPosition + normalWidth * endTopJoin;
	vec2 bBotPosition = bPosition + normalWidth * endBottomJoin;

	//position is normalized 0..1 coord on the screen
	vec2 position = (aTopPosition * lineTop + aBotPosition * lineBot) * lineStart + (bTopPosition * lineTop + bBotPosition * lineBot) * lineEnd;

	gl_Position = vec4(position  * 2.0 - 1.0, 0, 1);


	vec4 miterWidth = vec4(vec2(normalize(startJoin)), vec2(normalize(endJoin))) * thickness * pixelRatio * miterLimit * .5;

	//provides miter slicing
	startCutoff = vec4(aCoord, aCoord);
	startCutoff.zw += (prevCoord == aCoord ? startBottomJoin : vec2(-startJoin.y, startJoin.x)) / scaleRatio;
	startCutoff = (startCutoff + translate.xyxy) * scaleRatio.xyxy;
	startCutoff += viewport.xyxy;
	startCutoff += miterWidth.xyxy;

	endCutoff = vec4(bCoord, bCoord);
	endCutoff.zw += (nextCoord == bCoord ? endTopJoin : vec2(-endJoin.y, endJoin.x))  / scaleRatio;
	endCutoff = (endCutoff + translate.xyxy) * scaleRatio.xyxy;
	endCutoff += viewport.xyxy;
	endCutoff += miterWidth.zwzw;

	tangent = currTangent;

	fragColor = (lineEnd * bColor + lineStart * aColor) / 255.;
}
