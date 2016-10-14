/* global d3 */

angular.module("RIF")
        .directive('histImg', function ($parse) {
            var directiveDefinitionObject = {
                restrict: 'E',
                replace: false,
                scope: {
                    data: '=chartData',
                    breaks: '=chartBreaks'
                },
                link: function (scope, element, attrs) {

                    scope.$watch(function () {

                        d3.select("#domainHistogram").remove();

                        var border = 0.5;
                        var bordercolor = 'gray';

                        var margin = {top: 10, right: 30, bottom: 20, left: 30};
                        var width = 800 - margin.left - margin.right;
                        var height = 175 - margin.top - margin.bottom;

                        var max = d3.max(scope.data);
                        var min = d3.min(scope.data);
                        var x = d3.scale.linear()
                                .domain([min, max])
                                .range([0, width]);

                        var data = d3.layout.histogram()
                                .bins(x.ticks(100))
                                (scope.data);

                        var yMax = d3.max(data, function (d) {
                            return d.length;
                        });
                        var yMin = d3.min(data, function (d) {
                            return d.length;
                        });

                        var y = d3.scale.linear()
                                .domain([0, yMax])
                                .range([height, 0]);

                        var xAxis = d3.svg.axis()
                                .scale(x)
                                .orient("bottom");

                        //canvas
                        var svg = d3.select(element[0]).append("svg")
                                .attr("id", "domainHistogram")
                                .attr("width", width + margin.left + margin.right)
                                .attr("height", height + margin.top + margin.bottom)
                                .attr("border", border)
                                .append("g")
                                .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

                        //border box
                        var borderPath = svg.append("rect")
                                .attr("x", 0)
                                .attr("y", 0)
                                .attr("height", height)
                                .attr("width", width)
                                .style("stroke", bordercolor)
                                .style("fill", "none")
                                .style("stroke-width", border);

                        //bins
                        var bar = svg.selectAll(".bar")
                                .data(data)
                                .enter().append("g")
                                .attr("class", "bar")
                                .attr("transform", function (d) {
                                    return "translate(" + x(d.x) + "," + y(d.y) + ")";
                                });

                        //vertical reference lines
                        var breakRefs = svg.selectAll('.breakRefs')
                                .data(scope.breaks)
                                .enter().append("line")
                                .attr("stroke", "#d472bc")
                                .attr("stroke-width", 2)
                                .attr('x1', function (d) {
                                    return x(d);
                                })
                                .attr('x2', function (d) {
                                    return x(d);
                                })
                                .attr('y1', 0)
                                .attr('y2', height);

                        bar.append("rect")
                                .attr("x", 1)
                                .attr("width", (x(data[0].dx) - x(0)) - 1)
                                .attr("height", function (d) {
                                    return height - y(d.y);
                                })
                                .attr("fill", "#1caff6");

                        svg.append("g")
                                .attr("class", "x axis")
                                .attr("transform", "translate(0," + height + ")")
                                .call(xAxis);

                        svg.select(".x.axis")
                                .selectAll(".text")
                                .style("fill", "#999999");

                    });
                }
            };
            return directiveDefinitionObject;
        });
