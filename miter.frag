precision highp float;

uniform sampler2D dashPattern;
uniform float dashLength, pixelRatio;

varying vec4 fragColor;
varying float fragLength;
varying vec2 tangent;
varying vec4 startCutoff, endCutoff;

//get shortest distance from point p to line [a, b]
float distToLine(vec2 p, vec4 line) {
	vec2 a = line.xy, b = line.zw;
	vec2 diff = b - a;
	vec2 perp = normalize(vec2(-diff.y, diff.x));
	return dot(p - a, perp);
}

void main() {
	float alpha = 1., distToStart, distToEnd;

	distToStart = distToLine(gl_FragCoord.xy, startCutoff);
	if (distToStart < 0.) {
		discard;
		return;
	}

	distToEnd = distToLine(gl_FragCoord.xy, endCutoff);
	if (distToEnd < 0.) {
		discard;
		return;
	}

	alpha *= min(max(distToStart, 0.), 1.);
	alpha *= min(max(distToEnd, 0.), 1.);

	float t = fract(dot(tangent, gl_FragCoord.xy) / dashLength / pixelRatio) * .5 + .25;

	gl_FragColor = fragColor;
	gl_FragColor.a *= alpha * texture2D(dashPattern, vec2(t, 0.)).r;
}
