$(function () {
  var graphElement = $('.dashboard-market-graph');
  var graphWidth = graphElement.width();
  var graphData = graphElement.data('graph-series');
  var graphSmallestY = 100;
  $.each(graphData[0].data, function(i, v) {
    graphSmallestY = Math.min(v[1], graphSmallestY);
  });
  
  graphElement.highcharts({
    chart: {
      type: 'area',
      spacing: [20, 0, 0, 0],
      style: {
        overflow: 'visible'
      }
    },
    plotOptions: {
      area: {
        animation: false,
        marker: {
          enabled: false,
          radius: 2.5,
          lineWidth: 1,
          fillColor: '#ffffff',
          lineColor: '#3c5db3'
        },
        fillColor: '#d9e3ed',
        color: '#3c5db3',
        lineWidth: 1,
        fillOpacity: 1,
        states: {
          hover: {
            enabled: true,
            lineWidth: 1,
            halo: false
          }
        }
      }
    },
    title: {
      text: ''
    },
    legend: {
      enabled: false
    },
    tooltip: {
      animation: false,
      backgroundColor: '#ffffff',
      borderColor: '#d9e3ed',
      headerFormat: '',
      hideDelay: 0,
      pointFormat: '',
      positioner: function(labelWidth, labelHeight, point) {
        var halfLabelWidth = labelWidth / 2;
        var tipPoint = {x: point.plotX - halfLabelWidth, y: -1 * labelHeight};
        tipPoint.x = Math.max(tipPoint.x, -20);
        tipPoint.x = Math.min(tipPoint.x, (graphWidth - labelWidth) + 20);
        return tipPoint;
      },
      formatter: function() {
        return "<span class=\"graph-tooltip-label\">" + Highcharts.dateFormat('%b %e', Date.parse(this.points[0].key)) + "</span> <span class=\"graph-tooltip-value\">" + this.y + "%</span>";
      },
      shape: 'callout',
      shared: true,
      shadow: {
        opacity: 0.1,
        offsetX: 0,
        offsetY: 1,
        width: 2
      },
      useHTML: true
    },
    xAxis: {
      type: 'datetime',
      labels: {
        enabled: false
      },
      title: {
        text: null
      },
      startOnTick: false,
      endOnTick: false,
      tickPositions: [],
      maxPadding: 0,
      minPadding: 0,
      lineWidth: 0,
      gridLineWidth: 0,
      lineColor: 'transparent'
    },
    yAxis: {
      endOnTick: false,
      startOnTick: false,
      labels: {
        enabled: false
      },
      title: {
        text: null
      },
      tickPositions: [0],
      lineWidth: 0,
      gridLineWidth: 0,
      lineColor: 'transparent',
      min: graphSmallestY
    },
    series: graphData,
    credits: {
      enabled: false
    }
  })
});