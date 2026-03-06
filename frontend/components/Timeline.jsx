'use client';

import React, { useEffect, useRef, useState } from 'react';
import * as d3 from 'd3';
import styles from './Timeline.module.css';

export default function Timeline({ data = [], onBrushChange = null }) {
  const svgRef = useRef();
  const [tooltip, setTooltip] = useState(null);
  const [brushSelection, setBrushSelection] = useState(null);

  useEffect(() => {
    if (!data || data.length === 0 || !svgRef.current) return;

    // Set Chart dimensions
    const margin = { top: 20, right: 30, bottom: 60, left: 60 };
    const width = 1000 - margin.left - margin.right;
    const height = 400 - margin.top - margin.bottom;

    // Clear previous content
    d3.select(svgRef.current).selectAll("*").remove();

    // Create SVG
    const svg = d3.select(svgRef.current)
      .attr('width', width + margin.left + margin.right)
      .attr('height', height + margin.top + margin.bottom)
      .append('g')
      .attr('transform', `translate(${margin.left},${margin.top})`);

    // Parse dates
    const earthquakes = data.map(d => ({
      ...d,
      date: new Date(d.timestamp),
    }));

    // Create scales
    const xScale = d3.scaleTime()
      .domain(d3.extent(earthquakes, d => d.date))
      .range([0, width]);

    const yScale = d3.scaleLinear()
      .domain([0, d3.max(earthquakes, d => d.magnitude)])
      .range([height, 0]);

    const radiusScale = d3.scaleSqrt()
      .domain([0, d3.max(earthquakes, d => d.magnitude)])
      .range([2, 15]);

    // Create axes
    const xAxis = d3.axisBottom(xScale);
    const yAxis = d3.axisLeft(yScale);

    // Add X axis
    svg.append('g')
      .attr('transform', `translate(0,${height})`)
      .call(xAxis)
      .append('text')
      .attr('x', width / 2) 
      .attr('y', 40)
      .attr('fill', 'black')
      .style('text-anchor', 'middle')
      .text('Date');

    // Add Y axis
    svg.append('g')
      .call(yAxis)
      .append('text')
      .attr('transform', 'rotate(-90)')
      .attr('y', 0 - margin.left)
      .attr('x', 0 - height / 2)
      .attr('dy', '1em')
      .style('text-anchor', 'middle')
      .attr('fill', 'black')
      .text('Magnitude');

    // Add grid lines
    svg.append('g')
      .attr('class', 'grid')
      .attr('opacity', 0.1)
      .call(d3.axisLeft(yScale)
        .tickSize(-width)
        .tickFormat('')
      );

    // Create circles for each earthquake
    svg.selectAll('circle')
      .data(earthquakes)
      .enter()
      .append('circle')
      .attr('cx', d => xScale(d.date))
      .attr('cy', d => yScale(d.magnitude))
      .attr('r', d => radiusScale(d.magnitude))
      .attr('fill', d => {
        // Color by magnitude
        if (d.magnitude >= 7) return '#d62728'; // Red for 7+
        if (d.magnitude >= 6) return '#ff7f0e'; // Orange for 6+
        if (d.magnitude >= 5) return '#ffbb78'; // Light orange for 5+
        return '#1f77b4'; // Blue for <5
      })
      .attr('opacity', 0.7)
      .attr('stroke', '#333')
      .attr('stroke-width', 1)
      .style('pointer-events', 'auto')
      .on('mouseover', function(event, d) {
        d3.select(this)
          .attr('opacity', 1)
          .attr('stroke-width', 2);
        setTooltip({
          x: event.pageX,
          y: event.pageY,
          data: d,
        });
      })
      .on('mouseout', function() {
        d3.select(this)
          .attr('opacity', 0.7)
          .attr('stroke-width', 1);
        setTooltip(null);
      });
   function master_feedback() {

      //if (d3.event.sourceEvent && (d3.event.sourceEvent.type === "mousemove" || d3.event.sourceEvent.type === "touchmove")) {
      //     //array from brush sensor or use default x-axis range
      //     var sensor = d3.event.selection || _masterChart().x.range();

      //     //provide feedback from master to slave
      //     //drive domain mapping sensor output over master x-min and max values
      //     _slaveChart().x.domain(sensor.map(_masterChart().x.invert, _masterChart().x));
      //     //rescale the x axis after setting the domain.
      //     _slaveChart().chart.select(".axis--x").call(_slaveChart().xAxis);

      //     _slaveChart().chart.select(".zoom").call(zoom_ratio.transform, d3.zoomIdentity
      //         .scale(_tfc_layout_slave().width / (sensor[1] - sensor[0]))
      //         .translate(-sensor[0], 0));
      
      //}
      // _slaveChart().chart.selectAll(".dot")
      //  .attr('cx', function (d) { return _slaveChart().x(d[date_dynField]); })
      //  .attr('cy', _tfc_layout_slave.height() * 0.7);
      //  _slaveChart().chart.selectAll('.tick line')
      //    .attr("y1", function(d){
      //       return - _slaveChart().settings().height;
      //  });
        svg.selectAll(".handle")
        .attr("width",20)
        .attr("height",20)
        .attr("y",-4)
        .attr("rx", 20)
        .attr("ry", 20);
    }
    //Setup Brush sensor for master chart's time filter
    const brush_sensor_master = d3.brushX()
            .extent([[0, 0], [width, height]])
            .on("brush end", master_feedback);

                // Append brush to master chart
    svg.append("g")
        .attr("class", "brush brush-sensor brush-sensor-master")
      //  .attr("rx": "20")
        //.attr("ry": "20")
        .call(brush_sensor_master)
        .call(brush_sensor_master.move, null); //_masterChart().x.range());

        var handles_chart = svg.selectAll(".handle");
        handles_chart
        .attr("width",20)
        .attr("height",20)
        .attr("y",-4)
        .attr("rx", 20)
        .attr("ry", 20);
    /* ===== BRUSH CODE (COMMENTED OUT FOR LEARNING) =====
    // Brush event handlers
    function brushed(event) {
      if (!event.selection) return;

      const [x0, x1] = event.selection.map(xScale.invert);
      
      setBrushSelection({
        start: new Date(x0),
        end: new Date(x1),
      });

      // Call parent callback if provided
      if (onBrushChange) {
        onBrushChange({
          startDate: x0.toISOString().split('T')[0],
          endDate: x1.toISOString().split('T')[0],
        });
      }
    }

    function brushEnd(event) {
      // Clear brush on double-click (empty selection)
      if (!event.selection) {
        setBrushSelection(null);
        if (onBrushChange) {
          onBrushChange(null);
        }
      }
    }

    // Create brush
    const brush = d3.brushX()
      .extent([[0, 0], [width, height]])
      .on('brush', brushed)
      .on('end', brushEnd);

    // Add brush group
    const brushGroup = svg.append('g')
      .attr('class', 'brush')
      .call(brush);
  


        
    // Start with empty selection (no brush visible)
    brushGroup.call(brush.move, null);

    // Style brush overlay to allow interaction
    brushGroup.selectAll('.overlay')
      .style('cursor', 'crosshair');

    brushGroup.selectAll('.selection')
      .attr('fill', '#667eea')
      .attr('opacity', 0.2)
      .attr('stroke', '#667eea')
      .attr('stroke-width', 2);

    // Hide handles initially (they will show after selection)
    brushGroup.selectAll('.handle')
      .attr('width', 8)
      .attr('fill', '#667eea')
      .attr('stroke', '#333')
      .attr('stroke-width', 2)
      .style('cursor', 'ew-resize')
      .style('opacity', 0)
      .style('display', 'none');

    // Show handles only when brush is active
    brushGroup.on('mousedown', function() {
      brushGroup.selectAll('.handle')
        .style('opacity', 0.9)
        .style('display', 'block');
    });
    ===== END BRUSH CODE ===== */

  }, [data, onBrushChange]);

  return (
    <div className={styles.timelineContainer}>
      <svg ref={svgRef}></svg>
      
      {tooltip && (
        <div
          className={styles.tooltip}
          style={{
            left: `${tooltip.x + 10}px`,
            top: `${tooltip.y - 30}px`,
          }}
        >
          <div><strong>{tooltip.data.location}</strong></div>
          <div>Magnitude: {tooltip.data.magnitude.toFixed(2)}</div>
          <div>Depth: {tooltip.data.depth.toFixed(1)} km</div>
          <div>{new Date(tooltip.data.timestamp).toLocaleString()}</div>
        </div>
      )}

      {/* Brush selection info (commented out until brush is re-enabled) */}
      {/* {brushSelection && (
        <div className={styles.brushInfo}>
          <strong>Selected Range:</strong> {brushSelection.start.toLocaleDateString()} to {brushSelection.end.toLocaleDateString()}
        </div>
      )} */}
    </div>
  );
}
