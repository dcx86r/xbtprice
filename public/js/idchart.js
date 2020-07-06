var chart = LightweightCharts.createChart(document.body, {
	width: 800,
	height: 400,
	layout: {
		backgroundColor: '#ffffff',
		textColor: 'rgba(33, 56, 77, 1)',
	},
	grid: {
		vertLines: {
			color: 'rgba(197, 203, 206, 0.7)',
		},
		horzLines: {
			color: 'rgba(197, 203, 206, 0.7)',
		},
	},
	timeScale: {
		timeVisible: true,
		secondsVisible: false,
	},
});

var lineSeries = chart.addLineSeries();

var xhr = new XMLHttpRequest();
xhr.open('Get', 'http://127.0.0.1:3000/day');
xhr.send();
xhr.onload = function() {
	if(xhr.status === 200) {
		const data = JSON.parse(this.responseText);
		console.log(data);
		lineSeries.setData(data);
	}
}
