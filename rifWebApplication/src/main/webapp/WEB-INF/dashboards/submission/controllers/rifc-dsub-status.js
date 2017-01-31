/**
 * The Rapid Inquiry Facility (RIF) is an automated tool devised by SAHSU 
 * that rapidly addresses epidemiological and public health questions using 
 * routinely collected health and population data and generates standardised 
 * rates and relative risks for any given health outcome, for specified age 
 * and year ranges, for any given geographical area.
 *
 * Copyright 2016 Imperial College London, developed by the Small Area
 * Health Statistics Unit. The work of the Small Area Health Statistics Unit 
 * is funded by the Public Health England as part of the MRC-PHE Centre for 
 * Environment and Health. Funding for this project has also been received 
 * from the United States Centers for Disease Control and Prevention.  
 *
 * This file is part of the Rapid Inquiry Facility (RIF) project.
 * RIF is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * RIF is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with RIF. If not, see <http://www.gnu.org/licenses/>; or write 
 * to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
 * Boston, MA 02110-1301 USA

 * David Morley
 * @author dmorley
 */

/* 
 * CONTROLLER for disease submission status modal
 */

angular.module("RIF")
        .controller('ModalStatusCtrl', ['$scope', '$uibModal', 'user', 'uiGridConstants',
            function ($scope, $uibModal, user, uiGridConstants) {

                $scope.statusTableOptions = {
                    enableFiltering: true,
                    enableColumnResizing: true,
                    enableRowHeaderSelection: false,
                    enableHorizontalScrollbar: 0,
                    rowHeight: 25,
                    rowTemplate: rowTemplate(),
                    columnDefs: [
                        {
                            name: 'study_id', enableHiding: false, type: 'number', width: 75,
                            sort: {
                                direction: uiGridConstants.DESC,
                                priority: 0
                            }
                        },
                        {name: 'study_name', enableHiding: false, width: 150},
                        {name: 'study_description', enableHiding: false, width: 125},
                        {name: 'message', enableHiding: false, width: "*"},
                        {name: 'date', enableHiding: false, width: 150},
                        {name: 'study_state', enableHiding: false, width: 100}
                    ],
                    onRegisterApi: function (gridApi) {
                        $scope.gridApi = gridApi;
                    }
                };

                function rowTemplate() {
                    return  '<div id="testdiv" tabindex="0">' +
                            '<div style="height: 100%" ng-class="{ ' +
                            "statusC: row.entity.study_state==='C'," + //C: created, not verfied
                            "statusV: row.entity.study_state==='V'," + //V: verified, but no other work done;
                            "statusE: row.entity.study_state==='E'," + //E: extracted imported or created
                            "statusR: row.entity.study_state==='R'," + //R: results computed
                            "statusU: study_state==='U'," + //U: upgraded record from V3.1 RIF (has an indeterminate state; probably R.
                            '}">' +
                            '<div ng-repeat="(colRenderIndex, col) in colContainer.renderedColumns track by col.colDef.name" class="ui-grid-cell" ui-grid-cell></div>' +
                            '</div>';
                }

                user.getCurrentStatusAllStudies(user.currentUser).then(function (res) {
                    $scope.summary = res.data.smoothed_results;
                    $scope.statusTableOptions.data = $scope.summary;
                }, handleStudyError);

                function handleStudyError(e) {
                    $scope.showError("Could not retrieve study status");
                }

                $scope.open = function () {
                    var modalInstance = $uibModal.open({
                        animation: true,
                        templateUrl: 'dashboards/submission/partials/rifp-dsub-status.html',
                        controller: 'ModalStatusInstanceCtrl',
                        windowClass: 'status-Modal',
                        keyboard: false
                    });
                };
            }])
        .controller('ModalStatusInstanceCtrl', function ($scope, $uibModalInstance) {
            $scope.close = function () {
                $uibModalInstance.dismiss();
            };
            $scope.submit = function () {
                $uibModalInstance.close();
            };
        });