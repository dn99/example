<%@ page language="java" errorPage="/identity/anonymous/error.jsp" pageEncoding="UTF-8" contentType="text/html;charset=utf-8"%>
<%@ page import="com.samsung.core.util.CommonTool"%>
<%@ page import="org.anyframe.util.StringUtil"%>
<%@ page import="com.samsung.wwps.monitor.entity.MonitorCommData"%>
<%@ page import="java.util.List"%>
<%@ page import="com.samsung.commonCode.entity.CommCode"%>
<%@ include file="/jsp/common/taglibs.jsp"%>
<%@ include file="./common/libsJS.jsp"%>
<%@ include file="./common/libsChart.jsp"%>

<%
	CommonTool tool = new CommonTool(request.getContextPath());
	String lang = (String) request.getAttribute("localeLanguage");
	
	MonitorCommData searchData = (MonitorCommData) request.getAttribute("searchData");
	List<CommCode> issueList = searchData.getIssueList();
%>

<script type="text/javascript">
	google.charts.load('current', {packages:['bar','corechart','line']});
	google.charts.setOnLoadCallback(drawChart);
	
	var isSearch = false;
	var isAdmin = "${searchData.authority}";
	
	// graph Data 전역변수
	var percentByItem                         ; // 항목별 비율
	var monthlyComparisonByItem               ; // 월별 항목별 비교
	var monthlyUnsolved                       ; // 월별 미완료
	var monthlySuspicionOccur                 ; // 월별 확인대상 발생
	var monthlyViolationAndCompensationPayment; // 월별 확인결과 및 보상지급
	var monthlyCountBySystem                  ; // System별 건수
	var monthlyCountByBusiness                ; // 사업부별 건수
	var monthlyCountByDepartment              ; // 부서별 건수
	var monthlyCountByProcess                 ; // 공정별 건수
	var monthlyCountByWorkingTeam             ; // 분임조별 건수
	
	var gColor10 = [ '#3366cc'
	        	   , '#dc3912'
	        	   , '#ff9900'
	        	   , '#109618'
	        	   , '#990099'
	        	   , '#0099c6'
	        	   , '#dd4477'
	        	   , '#66aa00'
	        	   , '#b82e2e'
	        	   , '#316395' ];
	

	// 파이 그래프 공통 옵션
	function pieOptions(){
		return {
			  width:"100%"
			, height:500
			, legend:{position:"right", maxLines:2, alignment:'center'}
			, is3D: true
			, sliceVisibilityThreshold: 0
			, pieSliceText:'percentage' //'label', 'value', 'percentage'
			, pieSliceTextStyle:{fontSize:16}
			};
	}
	
	// bar그래프 공통 옵션1
	function barOptions1(){
		return {
	          width:'100%',
	          legend: { position: 'top', maxLines: 2 },
	          bar: { groupWidth: '75%' },
	          isStacked: true
	        };
	}
	
	// bar그래프 공통 옵션2
	function barOptions2(){
		return {
	          width:"100%",	          
	          legend: { position: 'top', maxLines: 2 },
	          bar: { groupWidth: '75%' }
	        };
	}
	
	// 꺾은선 그래프 공통 옵션
	function lineOptions(){
		return { width:"100%"
			   , legend: { position: 'top', maxLines: 2},
			   };
	}
	
	$(document).ready(function (){
		
		fnInit();
		addEvent();
		
		$(window).resize(function(){
			if(isSearch){
				fnSearch();
			}
	    });
		
		// 프로세스 체인지 이벤트
		$("select[id=schProcess]").change(function (){
			var code = $(this).val();
			
			// 부서 목록 세팅 함수 호출(parameter : 사업부 코드, 프로세스 코드)
			if("2" === $('#schBusinessCode')[0].sumo.getSelectStat()){
				getAjaxDeptList($("#schBusinessCode").val(), code);
			}else{
				getAjaxDeptList(null, code);
			}
			
			if(code == "06" || code == ""){ // 프로세스 항목 전체 또는 제조 선택시 공정, 분임조 활성
				
				$("#schGongjeong"  )[0].sumo.enable();
		    	$("#schWorkingTeam")[0].sumo.enable();
		    	
// 		    	if("2" === $("#schDeptCode")[0].sumo.getSelectStat()){
// 		    		getAjaxProcPartyList($("#schDeptCode").val());
// 		    	}else{
// 		    		getAjaxProcPartyList(null);
// 		    	}
		    	if("2" === getSelectStat()){
		    		getAjaxProcPartyList(deptTreeSelect.val());
		    	}else{
		    		getAjaxProcPartyList(null);
		    	}
			
			}else{ // 프로세스 항목 전체 또는 제조가 아니면 공정, 분임조 항목 전체로 초기화 하고 비활성

		    	$("#schGongjeong"  )[0].sumo.selectAll();
		    	$("#schGongjeong"  )[0].sumo.disable();
		    	
		    	$("#schWorkingTeam")[0].sumo.unSelectAll();
		    	$("#schWorkingTeam")[0].sumo.removeAll();
		    	$("#schWorkingTeam")[0].sumo.selectAll();
		    	$("#schWorkingTeam")[0].sumo.disable();		    	
			}
		});
		
		$("select[name=slChangeChart]").change(function (){
			var divNb = this.id.replace('slChangeChart','');
			
			switch(divNb){
			case "1":
				setChart1(this.value);
				break;
// 			case "2":
// 				setChart2(this.value);
// 				break;
// 			case "3":
// 				setChart3(this.value);
// 				break;
// 			case "4":
// 				setChart4(this.value);
// 				break;
// 			case "5":
// 				setChart5(this.value);
// 				break;
// 			case "6":
// 				setChart6(this.value);
// 				break;
// 			case "7":
// 				setChart7(this.value);
// 				break;
// 			case "8":
// 				setChart8(this.value);
// 				break;
// 			case "9":
// 				setChart9(this.value);
// 				break;
// 			case "10":
// 				setChart10(this.value);
// 				break;
			}
		});
		
			//검색조건 멀티 셀렉트 적용
			// 프로세스
			//$("#schProcess").SumoSelect({ csvDispCount: 2, selectAll:true, search: false, searchText:'Enter here.', captionFormat: '{0}건 선택', captionFormatAllSelected: '전체({0})',floatWidth:500 });		
			//$('#schProcess')[0].sumo.selectAll();
			// 사업부
			$("#schBusinessCode").SumoSelect({ csvDispCount: 2, selectAll:true, search: false, searchText:'Enter here.', captionFormat: '{0}건 선택', captionFormatAllSelected: '전체({0})',floatWidth:500 });		
			$('#schBusinessCode')[0].sumo.selectAll();
			$(".sumo_schBusinessCode").css("width","100%");
			$(".sumo_schBusinessCode").css("left","0px");
			
			// 부서
	// 		$("#schDeptCode").SumoSelect({ csvDispCount: 2, selectAll:true, search: true, searchText:'Enter here.', captionFormat: '{0}건 선택', captionFormatAllSelected: '전체({0})',placeholder:'전체' });		
	// 		$('#schDeptCode')[0].sumo.selectAll();
	// 		$(".sumo_schDeptCode").css("width","100%");
	// 		$(".sumo_schDeptCode").css("left","0px");
			
			// 공정
			$("#schGongjeong").SumoSelect({ csvDispCount: 2, selectAll:true, search: false, searchText:'Enter here.', captionFormat: '{0}건 선택', captionFormatAllSelected: '전체({0})',placeholder:'선택' });		
			$('#schGongjeong')[0].sumo.selectAll();	
			$(".sumo_schGongjeong").css("width","100%");
			$(".sumo_schGongjeong").css("left","0px");
			
			// 분임조
			$("#schWorkingTeam").SumoSelect({ csvDispCount: 2, selectAll:true, search: false, searchText:'Enter here.', captionFormat: '{0}건 선택', captionFormatAllSelected: '전체({0})',placeholder:'전체' });		
			$('#schWorkingTeam')[0].sumo.selectAll();
			$(".sumo_schWorkingTeam").css("width","100%");
			$(".sumo_schWorkingTeam").css("left","0px");

			if("" != $("#schProcess").val() && "06" != $("#schProcess").val()){
				$("#schGongjeong")[0].sumo.disable();
				$("#schWorkingTeam")[0].sumo.disable();
			}
			
// 		$("#slChangeValue1").SumoSelect({ csvDispCount: 2, selectAll:true, search: false, searchText:'Enter here.', captionFormat: '{0}건 선택', captionFormatAllSelected: '전체({0})' });		
// 		$('#slChangeValue1')[0].sumo.selectAll();
		
// 		$("#slChangeValue2").SumoSelect({ csvDispCount: 2, selectAll:true, search: false, searchText:'Enter here.', captionFormat: '{0}건 선택', captionFormatAllSelected: '전체({0})' });		
// 		$('#slChangeValue2')[0].sumo.selectAll();
		
// 		$("#slChangeValue8").SumoSelect({ csvDispCount: 2, selectAll:true, search: true , searchText:'Enter here.', captionFormat: '{0}건 선택', captionFormatAllSelected: '전체({0})' });		
// 		$('#slChangeValue8')[0].sumo.selectAll();
		
		// 사업부 변경 이벤트		
		$("#schBusinessCode").on("sumo:closed",function (){
			$.ajaxSetup({ async:false });
			if("1" === $(this)[0].sumo.getSelectStat()){ // 사업부 전체 선택했을때
				getAjaxDeptList(null, $("#schProcess").val());
			}else{
				getAjaxDeptList($(this).val(), $("#schProcess").val());
			}
			$.ajaxSetup({ async:true });
		});
		
		/* 
		// 부서 변경 이벤트
		$("#schDeptCode").on("sumo:closed",function (){
			var code = $("#schProcess").val();
			if(code == "06" || code == ""){ // 프로세스 항목 전체 또는 제조 선택시 공정, 분임조 조회				
				if("1" === $(this)[0].sumo.getSelectStat()){
					getAjaxProcPartyList(null);
				}else{
					getAjaxProcPartyList($(this).val());
				}
			}
		});
		 */
		 
		$("#slChangeValue1").on("sumo:closed",function (){
			setChart1($("#slChangeChart1").val());
		});
		
// 		$("#slChangeValue2").on("sumo:closed",function (){
// 			setChart2($("#slChangeChart2").val());
// 		});
		
// 		$("#slChangeValue8").on("sumo:closed",function (){
// 			setChart8($("#slChangeChart8").val());
// 		});
		
// 		if(isAdmin === "DIVISION_ADMIN" || isAdmin === "SUPPORT_ADMIN"){
// 			$("#schBusinessCode")[0].sumo.disable();
// 		}
		
		if(isAdmin === "DEPARTMENT_ADMIN" || isAdmin === "SDC_DEFAULT_ROLE" || isAdmin === "DIVISION_DEPARTMENT_ROLE"){
			$("#schBusinessCode")[0].sumo.disable();
// 			$("#schDeptCode")[0].sumo.disable();
			deptTreeSelect.disable();
		}
		
	});
	
	function numberWithCommas(x) {
		return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
	}
	
	function addEvent(){
		//달력 클릭
		$(".date_ico").click(function(e){
			var a = 1;
			var prev = $(this).prev();
			popUpMonthCalendar(prev[0], '-');
		});
	}
	
	function fnInit() {
		
		if("${search.schAppPeriod}" == "1"){
			document.getElementsByName("appPeriod")[0].className = "on";
		} else if("${search.schAppPeriod}" == "3") {
			document.getElementsByName("appPeriod")[1].className = "on";
		} else if("${search.schAppPeriod}" == "6") {
			document.getElementsByName("appPeriod")[2].className = "on";
		}
		
		//년월 셋팅
		var date = new Date();
		sysDate = date.getFullYear() + "-" + dateAddZero(date.getMonth()+1);
		
// 		getAjaxGraphData();
	}
	
	function fnAppPeriod(period) {
		$("#schAppPeriod").val(period);
		if(period == "1"){
			 document.getElementsByName("appPeriod")[0].className = "on";
			 document.getElementsByName("appPeriod")[1].className = "";
			 document.getElementsByName("appPeriod")[2].className = "";
		}else if(period == "3"){
			 document.getElementsByName("appPeriod")[0].className = "";
			 document.getElementsByName("appPeriod")[1].className = "on";
			 document.getElementsByName("appPeriod")[2].className = "";
		}else if(period == "6"){
			 document.getElementsByName("appPeriod")[0].className = "";
			 document.getElementsByName("appPeriod")[1].className = "";
			 document.getElementsByName("appPeriod")[2].className = "on";
		}
		
		var fromDt = addDate("m", -(parseInt(period))+2, sysDate, "-");
		$("#schAppFromDt").val(fromDt.substring(0,7));
		$("#schAppToDt"  ).val(sysDate);
	}

	// 항목별 비율
	function setChart1(chartType){
		var data    = null;
		var options = null;
		var chart   = null;
		var divId = 'graph1';
		var selBoxId = "slChangeValue1";
		
		document.getElementById(divId).innerHTML= "";
		
		switch(chartType){
		case "pie":
			chart = new google.visualization.PieChart(document.getElementById(divId));
			chart.draw(createPieGraphData(selBoxId,percentByItem), pieOptions());

			document.getElementById("divBox1").style.height = "360px";
			var graph1 = document.getElementById("graph1").childNodes[0];
			graph1.style.top = "-100px";
			graph1.style.position = "relative";
			graph1.style.zIndex = "-1";
			
			
			break;
		case "bar2":
			var d = [""];
			var dIdx = 0;
			var dd = [];
			var ddIdx = 0;
			var selChkCd = "|";
			
			if(selBoxId != null && selBoxId != ""){
				$("#"+selBoxId+" option:selected").each(function(){
					selChkCd = selChkCd+$(this).val()+"|";
				});
			}
			
			for(var i=0; i<percentByItem.length; i++){
			
				if(selChkCd.indexOf(percentByItem[i].deptCd) != -1){
					dd[ddIdx] = [percentByItem[i].deptNm,percentByItem[i].val0,gColor10[i]];
					ddIdx++;
				}
			}
			
			dd.unshift(['', 'Density', { role: 'style' } ]);
			
			data = google.visualization.arrayToDataTable(dd);
			options = {width:$("#sample tr").eq(0).find("td").eq(0).width()-20,
				vAxis:{
					format:'decimal'
				}
			,legend: { position: "none" },
			};
			
			chart = new google.visualization.ColumnChart(document.getElementById(divId));
			chart.draw(data, google.charts.Bar.convertOptions(options));
			break;
		}
		var alarmTotal = 0;
		for(var i=0; i<percentByItem.length; i++){
			if(percentByItem[i].deptCd == "07" || percentByItem[i].deptCd == "09"){
				var cnt = percentByItem[i].val0;
				
				$("#alarm"+percentByItem[i].deptCd).html(numberWithCommas(cnt));
				alarmTotal += cnt;
			}
		}
		
		$("#alarmTotal").html(numberWithCommas(alarmTotal));
		
	}
	// 월별 항목별 비교
	function setChart2(chartType){
		var chart   = null;
		var divId = 'graph2';
		var selBoxId = "slChangeValue2";
		
		document.getElementById(divId).innerHTML= "";
		
		switch(chartType){

		case "bar1":
			chart = new google.visualization.ColumnChart(document.getElementById(divId));
			chart.draw(createGraphData2(selBoxId,monthlyComparisonByItem), google.charts.Bar.convertOptions(barOptions1()));
			break;
		case "bar2":	        
			chart = new google.visualization.ColumnChart(document.getElementById(divId));
			chart.draw(createGraphData2(selBoxId,monthlyComparisonByItem), google.charts.Bar.convertOptions(barOptions2()));
			break;
		case "line":
		    chart = new google.visualization.LineChart(document.getElementById(divId));
		    chart.draw(createGraphData2(selBoxId,monthlyComparisonByItem), google.charts.Line.convertOptions(lineOptions()));
			break;
		}
		
	}
	// 월별 미완료
	function setChart3(chartType){
		var options = null;
		var chart   = null;
		var divId = 'graph3';
		
		document.getElementById(divId).innerHTML= "";
		
		switch(chartType){
		case "bar1":
			var options = {
		          width:'100%',
		          legend: { position: 'top', maxLines: 2 },
		          bar: { groupWidth: '75%' },
		          isStacked: true,
		          colors:['#dc3912','#109618']
		        }
			chart = new google.visualization.ColumnChart(document.getElementById(divId));
			chart.draw(createGraphData(null,monthlyUnsolved), google.charts.Bar.convertOptions(options));
			break;
		case "bar2":
			var options = {
		          width:"100%",	          
		          legend: { position: 'top', maxLines: 2 },
		          bar: { groupWidth: '75%' },
		          colors:['#dc3912','#109618']
		        };
			chart = new google.visualization.ColumnChart(document.getElementById(divId));
			chart.draw(createGraphData(null,monthlyUnsolved), google.charts.Bar.convertOptions(options));
			break;
		case "line":
		    options = { width:'100%'
		    		  , colors:['#dc3912','#109618']
		              , legend:{ position: 'top', maxLines: 2}
		              };

		    chart = new google.visualization.LineChart(document.getElementById(divId));
		    chart.draw(createGraphData(null,monthlyUnsolved), google.charts.Line.convertOptions(options));
			break;
		}
	}
	// 월별 확인대상 발생
	function setChart4(chartType){
		var options = null;
		var chart   = null;
		var divId = 'graph4';
		
		document.getElementById(divId).innerHTML= "";
		
		switch(chartType){
		case "bar1":
			options = {width:$("#sample tr").eq(0).find("td").eq(0).width()-20,
				legend: { position: 'top', maxLines: 3 },
				bar: { groupWidth: '75%' },
				isStacked: true,
				colors:['#dc3912','#ff9900']// 확인결과, 확인대상  //'#3366cc',
			};

			chart = new google.visualization.ColumnChart(document.getElementById(divId));
			chart.draw(createGraphData(null,monthlySuspicionOccur), google.charts.Bar.convertOptions(options));
			break;
		case "bar2":
			options = {width:$("#sample tr").eq(0).find("td").eq(0).width()-20,
				legend: { position: 'top', maxLines: 3 },
				bar: { groupWidth: '75%' },
				colors:['#dc3912','#ff9900'] //'#3366cc',
			};

			chart = new google.visualization.ColumnChart(document.getElementById(divId));
			chart.draw(createGraphData(null,monthlySuspicionOccur), google.charts.Bar.convertOptions(options));			
			break;
		case "line":
		    options = { width:'100%'
				      ,	colors:['#dc3912','#ff9900'] // '#3366cc',
		              , legend:{ position: 'top', maxLines: 2}
		              };

		    chart = new google.visualization.LineChart(document.getElementById(divId));
		    chart.draw(createGraphData(null,monthlySuspicionOccur), google.charts.Line.convertOptions(options));
			break;
		}
	}
	
	// 월별 확인결과 및 보상 지급
	function setChart5(chartType){
		var options = null;
		var chart   = null;
		var divId = 'graph5';
		
		document.getElementById(divId).innerHTML= "";
		
		switch(chartType){
		case "bar1":
			options = {width:$("#sample tr").eq(0).find("td").eq(0).width()-20,
				legend: { position: 'top', maxLines: 2 },
				bar: { groupWidth: '75%' },
					isStacked: true,
					colors:['#3366cc','#dc3912','#ff9900']
			};
			
			chart = new google.visualization.ColumnChart(document.getElementById(divId));
			chart.draw(createGraphData(null,monthlyViolationAndCompensationPayment), google.charts.Bar.convertOptions(options));
			break;
			case "bar2":
			options = {width:$("#sample tr").eq(0).find("td").eq(0).width()-20,
				legend: { position: 'top', maxLines: 2 },
				bar: { groupWidth: '75%' },
					colors:['#3366cc','#dc3912','#109618']
			};
			
			chart = new google.visualization.ColumnChart(document.getElementById(divId));
			chart.draw(createGraphData(null,monthlyViolationAndCompensationPayment), google.charts.Bar.convertOptions(options));
			break;
		case "line":
		    options = { width:"100%"
				      , colors:['#3366cc','#dc3912','#109618']
		              , legend:{ position: 'top', maxLines: 2}
		              };

		    chart = new google.visualization.LineChart(document.getElementById(divId));
		    chart.draw(createGraphData(null,monthlyViolationAndCompensationPayment), google.charts.Line.convertOptions(options));
			break;
		}
	}
	
	// System별 건수
	function setChart6(chartType){
		var chart   = null;
		var divId = 'graph6';
		
		document.getElementById(divId).innerHTML= "";
		
		switch(chartType){
		case "bar1":	        
			chart = new google.visualization.ColumnChart(document.getElementById(divId));
			chart.draw(createGraphData(null,monthlyCountBySystem), google.charts.Bar.convertOptions(barOptions1()));
			break;
		case "bar2":	        
			chart = new google.visualization.ColumnChart(document.getElementById(divId));
			chart.draw(createGraphData(null,monthlyCountBySystem), google.charts.Bar.convertOptions(barOptions2()));
			break;
		case "line":
		    chart = new google.visualization.LineChart(document.getElementById(divId));
		    chart.draw(createGraphData(null,monthlyCountBySystem), google.charts.Line.convertOptions(lineOptions()));
			break;
		}
	}
	
	// 사업부별
	function setChart7(chartType){
		var chart   = null;
		var divId = 'graph7';
		
		document.getElementById(divId).innerHTML= "";
		
		switch(chartType){
		case "bar1":
			chart = new google.visualization.ColumnChart(document.getElementById(divId));
			chart.draw(createGraphData(null,monthlyCountByBusiness), google.charts.Bar.convertOptions(barOptions1()));
			break;
		case "bar2":
			chart = new google.visualization.ColumnChart(document.getElementById(divId));
			chart.draw(createGraphData(null,monthlyCountByBusiness), google.charts.Bar.convertOptions(barOptions2()));
			break;
		case "line":
		    chart = new google.visualization.LineChart(document.getElementById(divId));
		    chart.draw(createGraphData(null,monthlyCountByBusiness), google.charts.Line.convertOptions(lineOptions()));
			break;
		}
	}
	// 부서별 건수
	function setChart8(chartType){
		var chart   = null;
		var divId = 'graph8';
		var selBoxId = "slChangeValue8";
		
		document.getElementById(divId).innerHTML= "";
		
		switch(chartType){
		case "bar1":
			chart = new google.visualization.ColumnChart(document.getElementById(divId));
			chart.draw(createGraphData(selBoxId,monthlyCountByDepartment), google.charts.Bar.convertOptions(barOptions1()));
			break;
		case "bar2":
			chart = new google.visualization.ColumnChart(document.getElementById(divId));
			chart.draw(createGraphData(selBoxId,monthlyCountByDepartment), google.charts.Bar.convertOptions(barOptions2()));
			break;
		case "line":
		    chart = new google.visualization.LineChart(document.getElementById(divId));
		    chart.draw(createGraphData(selBoxId,monthlyCountByDepartment), google.charts.Line.convertOptions(lineOptions()));
			break;
		}
	}
	
	// 공정별 건수
	function setChart9(chartType){
		var chart   = null;
		var divId = 'graph9';
		
		document.getElementById(divId).innerHTML= "";
		
		switch(chartType){
		case "bar1":
			chart = new google.visualization.ColumnChart(document.getElementById(divId));
			chart.draw(createGraphData(null,monthlyCountByProcess), google.charts.Bar.convertOptions(barOptions1()));
			break;
		case "bar2":
			chart = new google.visualization.ColumnChart(document.getElementById(divId));
			chart.draw(createGraphData(null,monthlyCountByProcess), google.charts.Bar.convertOptions(barOptions2()));
			break;
		case "line":
		    chart = new google.visualization.LineChart(document.getElementById(divId));
		    chart.draw(createGraphData(null,monthlyCountByProcess), google.charts.Line.convertOptions(lineOptions()));
			break;
		}
	}
	
	function setChart10(chartType){
		var chart   = null;
		var divId = 'graph10';
		
		document.getElementById(divId).innerHTML= "";
		
		if(monthlyCountByWorkingTeam.length > 0){
			switch(chartType){
			case "bar1":
				chart = new google.visualization.ColumnChart(document.getElementById(divId));
				chart.draw(createGraphData(null,monthlyCountByWorkingTeam), google.charts.Bar.convertOptions(barOptions1()));
				break;
			case "bar2":
				chart = new google.visualization.ColumnChart(document.getElementById(divId));
				chart.draw(createGraphData(null,monthlyCountByWorkingTeam), google.charts.Bar.convertOptions(barOptions2()));
				break;
			case "line":
				chart = new google.visualization.LineChart(document.getElementById(divId));
			    chart.draw(createGraphData(null,monthlyCountByWorkingTeam), google.charts.Line.convertOptions(lineOptions()));
				break;
			}
		}else{
			$("#"+divId).html("No Data Found.")
		}
	}
	
	function drawChart(){
		
		//fnSearch();
		
	}
	
	// 조회
	function fnSearch(){
		
		if(fnValidationCheck()){
			return;
		}
		isSearch = true;
		
		$("#schBusinessCode")[0].sumo.enable();
// 		$("#schDeptCode")[0].sumo.enable();
		deptTreeSelect.enable();
		
		deptTreeSelect.checkVal();
		
		getAjaxGraphData();
		
		if(isAdmin === "DIVISION_ADMIN" || isAdmin === "SUPPORT_ADMIN"){
			$("#schBusinessCode")[0].sumo.disable();
		}
		
		if(isAdmin === "DEPARTMENT_ADMIN" || isAdmin === "SDC_DEFAULT_ROLE" || isAdmin === "DIVISION_DEPARTMENT_ROLE"){
			$("#schBusinessCode")[0].sumo.disable();
// 			$("#schDeptCode")[0].sumo.disable();
			deptTreeSelect.disable();
		}
	}
	
	function getAjaxGraphData(){
		
		$.ajaxSetup({ async:false });		
		var url = contextPath + "/monitor/dashbordDetailData.do";
		var params = jQuery("#srchForm").serialize(); 
		$.ajaxSetup({
			async : true
		});

		sdpLoading();
		$
				.ajax({
					type : "POST",
					url : url,
					data : params,
					dataType : 'json',
					success : function(ret) {

						setDetailCountData(ret.data.detailCount);

						// 전역변수에 그래프 data를 담는다.
						percentByItem = ret.data.percentByItem;
						monthlyComparisonByItem = ret.data.monthlyComparisonByItem;
						monthlyUnsolved = ret.data.monthlyUnsolved;
						monthlySuspicionOccur = ret.data.monthlySuspicionOccur;
						monthlyViolationAndCompensationPayment = ret.data.monthlyViolationAndCompensationPayment;
						monthlyCountBySystem = ret.data.monthlyCountBySystem;
						monthlyCountByBusiness = ret.data.monthlyCountByBusiness;
						monthlyCountByDepartment = ret.data.monthlyCountByDepartment;
						monthlyCountByProcess = ret.data.monthlyCountByProcess;
						monthlyCountByWorkingTeam = ret.data.monthlyCountByWorkingTeam;

						setChart1($("#slChangeChart1").val());
// 						setChart2($("#slChangeChart2").val());
// 						setChart3($("#slChangeChart3").val());
// 						setChart4($("#slChangeChart4").val());
// 						setChart5($("#slChangeChart5").val());
// 						setChart6($("#slChangeChart6").val());
// 						setChart7($("#slChangeChart7").val());
// 						setChart8($("#slChangeChart8").val());
// 						setChart9($("#slChangeChart9").val());
// 						setChart10($("#slChangeChart10").val());

						hideLoading();
					},
					error : function(request, err, ex) {
						hideLoading();
						alert(err + " ===> " + ex);
					}
				});
	}

	function setDetailCountData(data) {
		$("#val0").html(numberWithCommas(data.val0) + " 건");
		$("#val1").html(numberWithCommas(data.val1) + " 건");
		$("#val2").html(numberWithCommas(data.val2) + " 건");
		$("#val3").html(numberWithCommas(data.val3) + " 건");
		$("#val4").html(numberWithCommas(data.val4) + " %");
		$("#val5").html(numberWithCommas(data.val5) + " 건");
	}

	function getAjaxDeptList(pCd, procCd) {
		var url = contextPath
				+ "/monitor/dashbordDetailDeptData.do?schDeptCode=" + pCd
				+ "&schProcess=" + procCd;
		var params = null;
		$.ajax({
			type : "POST",
			url : url,
			data : params,
			dataType : 'json',
			success : function(ret) {
				// 멀티 콤보 초기화
				// 		    	$('#schDeptCode')[0].sumo.unSelectAll(); // 멀티콤보 목록 체크 해제
				// 		    	$('#schDeptCode')[0].sumo.removeAll(); // 체크 해제된 목록 삭제
				deptTreeSelect.unSelectAll(); // 멀티콤보 목록 체크 해제
				deptTreeSelect.removeAll(); // 체크 해제된 목록 삭제

				// 		    	  if(pCd != "C10F4337"){ // 구매가 아니면
				// 			    	  for(var i=0 ;i<ret.data.list.length; i++){ // 목록 세팅
				// 			    		  $('#schDeptCode')[0].sumo.add(ret.data.list[i].code,ret.data.list[i].koLabel);    		  
				// 			    	  }
				// 		    	  }
				if (pCd != "C10F4337") { // 구매가 아니면
					setDataProvider(ret.data.list, procCd); // monDeptListTreeSelect.js function call
				}

				// 		    	  // 세팅 목록 전체 체크
				// 		    	  $('#schDeptCode')[0].sumo.selectAll();
			},
			error : function(request, err, ex) {
				hideLoading();
				alert(err + " ===> " + ex);

			}
		});
	}

	function getAjaxProcPartyList(pCd) {
		var url = contextPath
				+ "/monitor/dashbordDetailProcPartyData.do?schDeptCode=" + pCd;
		var params = null;

		$.ajax({
			type : "POST",
			url : url,
			data : params,
			dataType : 'json',
			success : function(ret) {

				$('#schWorkingTeam')[0].sumo.unSelectAll();
				$('#schWorkingTeam')[0].sumo.removeAll();

				for (var i = 0; i < ret.data.list2.length; i++) {
					$('#schWorkingTeam')[0].sumo.add(ret.data.list2[i].code,
							ret.data.list2[i].koLabel);
				}

				$('#schWorkingTeam')[0].sumo.selectAll();
			},
			error : function(request, err, ex) {
				hideLoading();
				alert(err + " ===> " + ex);

			}
		});
	}

	function fnValidationCheck() {

		// 대상월 체크
		if (checkSchDate()) {
			alert("대상월이 잘못 되었습니다.");
			return true;
		}

		// 사업부 체크		
		if ("0" == $('#schBusinessCode')[0].sumo.getSelectStat()) {
			alert("사업부를 선택 하세요.");
			return true;
		}

		// 부서 체크
		// 		if("0" == $('#schDeptCode')[0].sumo.getSelectStat()){
		// 			alert("부서를 선택 하세요."); return true;
		// 		}
		if ("0" == getSelectStat()) {
			alert("부서를 선택 하세요.");
			return false;
		}

		var code = $("#schProcess").val();

		if (code == "06" || code == "") {
			// 공정체크
			if ("0" == $('#schGongjeong')[0].sumo.getSelectStat()) { // 선택 한게 없으면
				alert("공정을 선택 하세요.");
				return true;
			} else if ("1" == $('#schGongjeong')[0].sumo.getSelectStat()) { // 공정 전체 선택이면
				$("#schGongjeongArr").val("");
			} else { // 일부만 선택 했을경우
				$("#schGongjeongArr").val($("#schGongjeong").val());
			}

			// 분임조 체크
			if ("0" == $('#schWorkingTeam')[0].sumo.getSelectStat()) {
				alert("분임조를 선택 하세요.");
				return true;
			} else if ("1" == $('#schWorkingTeam')[0].sumo.getSelectStat()) { // 분임조 전체 선택이면
				$("#schWorkingTeamArr").val("");
			} else { // 일부만 선택 했을경우
				$("#schWorkingTeamArr").val($("#schWorkingTeam").val());
			}
		} else {
			$("#schGongjeongArr").val("");
			$("#schWorkingTeamArr").val("");
		}

		return false;
	}

	function checkSchDate() {
		var sdd = $("#schAppFromDt").val();
		var edd = $("#schAppToDt").val();
		var ar1 = sdd.split('-');
		var ar2 = edd.split('-');
		var da1 = new Date(ar1[0], ar1[1], "01");
		var da2 = new Date(ar2[0], ar2[1], "01");
		var dif = da2 - da1;
		var cDay = 24 * 60 * 60 * 1000;// 시 * 분 * 초 * 밀리세컨
		var cMonth = cDay * 30;// 월 만듬
		var cYear = cMonth * 12; // 년 만듬

		if (parseInt(dif / cDay) < 0) {
			return true;
		}

		return false;
	}

	// 다중 꺾은선, 막대 데이터 생성
	function createGraphData(selBoxId, d) {

		var data = new google.visualization.DataTable();
		data.addColumn('string', '');

		var deptCd = "";
		var a = [];
		var aIdx = 0;
		var isYn = true;
		if (selBoxId != null && selBoxId != "") {
			var selChkCd = "|";
			$("#" + selBoxId + " option:selected").each(function() {
				selChkCd = selChkCd + $(this).val() + "|"
			});

			for (var i = 0; i < d.length; i++) {
				if (selChkCd.indexOf(d[i].deptCd) != -1) {
					if (deptCd != d[i].deptCd) {
						data.addColumn('number', d[i].deptNm);
					}
					if (deptCd != "" && deptCd != d[i].deptCd) {
						isYn = false;
						aIdx = 0;
					}
					if (isYn) {
						a[aIdx] = [ d[i].monthCd + "월", d[i].val0 ];
						aIdx++;
					} else {
						a[aIdx].push(d[i].val0);
						aIdx++;
					}
					deptCd = d[i].deptCd;
				}
			}
		} else {
			for (var i = 0; i < d.length; i++) {
				if (deptCd != d[i].deptCd) {
					data.addColumn('number', d[i].deptNm);
				}
				if (deptCd != "" && deptCd != d[i].deptCd) {
					isYn = false;
					aIdx = 0;
				}
				if (isYn) {
					a[aIdx] = [ d[i].monthCd + "월", d[i].val0 ];
					aIdx++;
				} else {
					a[aIdx].push(d[i].val0);
					aIdx++;
				}
				deptCd = d[i].deptCd;
			}
		}

		data.addRows(a);

		return data;
	}

	// 다중 꺾은선, 막대 데이터 생성
	function createGraphData2(selBoxId, d) {

		var data = new google.visualization.DataTable();
		data.addColumn('string', '');

		var deptCd = "";
		var a = [];
		var aIdx = 0;
		var isYn = true;

		var selChkCd = "|";

		if (selBoxId != null && selBoxId != "") {
			$("#" + selBoxId + " option:selected").each(function() {
				selChkCd = selChkCd + $(this).val() + "|"
			});
		}

		for (var i = 0; i < d.length; i++) {
			if (selChkCd.indexOf(d[i].yearMonth) != -1) {
				if (deptCd != d[i].deptCd) {
					data.addColumn('number', d[i].deptNm + "월");
				}

				if (deptCd != "" && deptCd != d[i].deptCd) {
					isYn = false;
					aIdx = 0;
				}

				if (isYn) {
					a[aIdx] = [ d[i].monthCd, d[i].val0 ];
					aIdx++;
				} else {
					a[aIdx].push(d[i].val0);
					aIdx++;
				}

				deptCd = d[i].deptCd;
			}
		}

		data.addRows(a);

		return data;
	}

	function createPieGraphData(selBoxId, d) {
		var a = [ [ 'Task', 'Hours per Day' ] ];
		var aIdx = 1;

		if (selBoxId != null && selBoxId != "") {

			var selChkCd = "|";

			$("#" + selBoxId + " option:selected").each(function() {
				selChkCd = selChkCd + $(this).val() + "|"
			});

			for (var i = 0; i < d.length; i++) {
				if (selChkCd.indexOf(d[i].deptCd) != -1) {
					a[aIdx] = [ d[i].deptNm, d[i].val0 ];
					aIdx++;
				}
			}
		} else {
			for (var i = 0; i < d.length; i++) {
				a[aIdx] = [ d[i].deptNm, d[i].val0 ];
				aIdx++;
			}
		}

		return google.visualization.arrayToDataTable(a);
	}

	// 엑셀다운로드
	function getExcelDownload() {

		if (!fnValidationCheck() && confirm("엑셀다운로드 하시겠습니까?")) {

			$("#schBusinessCode")[0].sumo.enable();
			// 			$("#schDeptCode")[0].sumo.enable();
			deptTreeSelect.enable();

			var url = contextPath + "/monitor/dashbordDetailExcel.do";
			fn_FormAction("srchForm", "post", "_self", url);

			if (isAdmin === "DIVISION_ADMIN" || isAdmin === "SUPPORT_ADMIN") {
				$("#schBusinessCode")[0].sumo.disable();
			}

			if (isAdmin === "DEPARTMENT_ADMIN"
					|| isAdmin === "SDC_DEFAULT_ROLE"
					|| isAdmin === "DIVISION_DEPARTMENT_ROLE") {
				$("#schBusinessCode")[0].sumo.disable();
				// 				$("#schDeptCode")[0].sumo.disable();
				deptTreeSelect.disable();
			}
		}
	}

	function fn_FormAction(formId, strMethod, strTarget, actionUrl) {
		var form = $("form[id=" + formId + "]");
		form.attr("method", strMethod);
		form.attr("target", strTarget);
		form.attr("action", actionUrl);
		form.submit();
	}
</script>



<div class="srch_wrap" style="">
	<!-- srch_wrap -->
	<form:form id="srchForm" name="srchForm">
		<input type="hidden" id="schGongjeongArr" name="schGongjeongArr" />
		<input type="hidden" id="schWorkingTeamArr" name="schWorkingTeamArr" />
		<div class="srch_form">
			<!-- srch_form -->
			<table class="srch_table">
				<!-- srch_table -->
				<colgroup>
					<col style="width: 10%;">
					<col style="width: 15%;">
					<col style="width: 10%;">
					<col style="width: 15%;">
					<col style="width: 10%;">
					<col style="width: 15%;">
					<col style="width: 10%;">
					<col style="width: 15%;">
				</colgroup>
				<tr>
					<th>대상월</th>
					<td colspan="5"><input type="hidden" id="schAppPeriod" /> <span
						class="month"> 최근 <a href="javascript:fnAppPeriod('1')"
							name="appPeriod">1개월</a><a href="javascript:fnAppPeriod('3')"
							name="appPeriod">3개월</a><a href="javascript:fnAppPeriod('6')"
							name="appPeriod">6개월</a></span> <span
						style="margin-left: 10px; display: inline-block"> <input
							type="date" style="width: 100px;" id="schAppFromDt"
							name="schAppFromDt"
							value="<c:out value="${search.schAppFromDt}"/>"><a
							href="javascript:addEvent();" class="date_ico"><img
								src="<c:url value='/images/common/ico_date.png'/>"
								alt="Calendar" title="Calendar" class="ico_date"></a> ~ <input
							type="date" style="width: 100px;" id="schAppToDt"
							name="schAppToDt"
							value="<c:out value="${search.schAppToDt  }"/>"><a
							href="javascript:addEvent();" class="date_ico"><img
								src="<c:url value='/images/common/ico_date.png'/>"
								alt="Calendar" title="Calendar" class="ico_date"></a></td>
					<th>프로세스</th>
					<td><select name="schProcess" id="schProcess"
						style="width: 100%">
							<c:if
								test="${searchData.authority eq 'SUPER_ADMIN' || searchData.authority eq 'SUPPORT_ADMIN'}">
								<option value="" selected="selected">전체</option>
							</c:if>
							<c:forEach var="obj" items="${searchData.processList}"
								varStatus="loopCount">
								<option value="${obj.code}"><c:out
										value="${obj.koLabel}" /></option>
							</c:forEach>
					</select></td>
				</tr>
				<tr>
					<th>사업부</th>
					<td style="position: relative;"><select
						name="schBusinessCode" id="schBusinessCode" multiple="multiple">
							<c:forEach var="obj" items="${searchData.divisionList}"
								varStatus="loopCount">
								<option value="${obj.code}"><c:out
										value="${obj.koLabel}" /></option>
							</c:forEach>
					</select></td>
					<th>부서</th>
					<td style="position: relative; min-width: 200px;">
						<div id="dept">
							<treeselect name="schDeptCode" id="schDeptCode"
								style="width:100%" v-model="value" noOptionsText="전체선택"
								:placeholder="placeholder" :multiple="true" :options="options"
								:value-consists-of="valueConsistsOf" :default-expand-level="0"
								:searchable="false" :disable-branch-nodes="false"
								:disabled="disabled" :alwaysOpen="true"
								@all="onAllHandler(event)" @open="onOpenHandler(event)"
								@close="onCloseHandler(event)" @clear="onClearHandler(event)"
								@deselect="onDeselectHandler(event)" />
						</div> <script>
							$(function() {
								var list = [];
								var item = null;
								<c:forEach var="dept" items="${searchData.deptList}" varStatus="loopCount">
								item = getItem("${dept.koLabel}",
										"${dept.code}",
										"${dept.upperCodeId}",
										"${dept.treeLevel}");
								list.push(item);
								</c:forEach>
								setDataProvider(list, $("#sourceSystem")
										.val());
							})
						</script> <script src="<c:url value='/js/wwps/monitor/monDeptListTreeSelect.js'/>"></script>
					</td>
					<%-- 
			<th class="tc">부서</th>
			<td style="position: relative;">
				<select name="schDeptCode" id="schDeptCode" style="width:100%" multiple="multiple">
					<c:forEach var="obj" items="${searchData.deptList}" varStatus="loopCount">
					<option value="${obj.code}"><c:out value="${obj.koLabel}"/></option>
					</c:forEach>
				</select>
			</td>
			 --%>
					<th class="tc">공정</th>
					<td style="position: relative;"><select name="schGongjeong"
						id="schGongjeong" style="width: 100%" multiple="multiple">
							<c:forEach var="obj" items="${searchData.gonjeongList}"
								varStatus="loopCount">
								<option value="${obj.code}"><c:out
										value="${obj.koLabel}" /></option>
							</c:forEach>
					</select></td>
					<th>분임조</th>
					<td style="position: relative;"><select name="schWorkingTeam"
						id="schWorkingTeam" style="width: 100%" multiple="multiple">
							<c:forEach var="obj" items="${searchData.teamList}"
								varStatus="loopCount">
								<option value="${obj.code}"><c:out
										value="${obj.koLabel}" /></option>
							</c:forEach>
					</select></td>
				</tr>
			</table>
			<!-- //srch_table -->

		</div>
		<!-- //srch_form -->
	</form:form>
	<div class="button">
		<a href="javascript:fnSearch();" class="btn_srch">조회</a>
	</div>
</div>
<!-- //srch_wrap -->

<div class="dash_wrap">
	<div class="info">
		프로세스 구분에 따라 일부 항목이 적용되지 않을 수 있습니다.<br> 공정, 분임조 데이터는 제조 G-EMS 모듈에만
		존재합니다.
	</div>
	<div class="button">
		<a href="javascript:getExcelDownload();" class="btn_list"><span
			class="ico_dw"></span>다운로드</a>
	</div>
	<div class="summary">
		<ul>
			<li><span>확인대상 : </span> <strong id="val0">0건</strong></li>
			<li><span>사전알람 : </span> <strong id="val5">0건</strong></li>
			<li><span>확인결과 : </span> <strong id="val1">0건</strong></li>
			<li><span>보상지급 : </span> <strong id="val2">0건</strong></li>
			<li><span>총거래 : </span> <strong id="val3">0건</strong></li>
			<li><span>확인결과비율 : </span> <strong id="val4">0%</strong></li>
		</ul>
	</div>
<!-- 	<div class="box5" id="divBox1"> -->
<!-- 		<header class="title">항목별 비율 -->
<!-- 			<select name="slChangeValue" id="slChangeValue1" class="second" style="width:120px;" multiple="multiple"> -->
<%-- 				<c:forEach var="obj" items="${searchData.issueList}" varStatus="loopCount">				 --%>
<%-- 				<c:if test="${obj.code ne '07' and obj.code ne '09'}"> --%>
<%-- 				<option value="${obj.code}">${obj.koLabel}</option> --%>
<%-- 				</c:if> --%>
<%-- 				</c:forEach> --%>
<!-- 			</select> -->
<!-- 			<select name="slChangeChart" id="slChangeChart1" style="width:60px"> -->
<!-- 				<option value="pie" selected="selected">파이</option> -->
<!-- 				<option value="bar2">막대</option>						 -->
<!-- 			</select> -->
<!-- 		</header> -->
<!-- 		<div class="chart" id="graph1"></div> -->
<!-- 	</div> -->

	<%-- 
	<c:forEach items="${searchData}" var="attribute" varStatus="status">
    	<c:set var="searchData" value="${attribute}" scope="request"/>
    </c:forEach>

	<c:import url="dashboard/db01.jsp"/>
	 --%>
	 
<%-- 	<c:forEach items="${searchData.issueList}" var="optionList1" varStatus="status">   --%>
	<%-- 
	<jsp:include page="dashboard/db01.jsp">
		<jsp:param name="headTitle" value="월별 항목별 비교"></jsp:param>
		<jsp:param name="className" value="box4"></jsp:param>
		<jsp:param name="isOption1" value="1"></jsp:param>
		<jsp:param name="isOption2" value="0"></jsp:param>
		<jsp:param name="optionData1" value="issueList"></jsp:param>
		<jsp:param name="optionData2" value="issueList"></jsp:param>
		<jsp:param name="optionList1" value="optionList1"></jsp:param>
	</jsp:include>
	 --%>
<%-- 	</c:forEach> --%>
	
	
<!-- 	<div id="app"> -->
<!-- 	    <my-component1 :propsdata="parentData"></my-component1> -->
<!-- 	    <my-component2></my-component2> -->
<!-- 	</div> -->

	<div id="divBox1" :class="className">
	  	<container :headTitle="headTitle" 
	             :isOption1="option1"
	             :isOption2="option2">
	             
	    	<divOption1>
<!-- 	    		<option value="aaa">aaa</option> -->
	    	</divOption1>
	         
	         <divOption2>
	         
	         </divOption2>
	             
	    </container>
	</div>
<%-- 	             :optionData1="<%=issueList %>" --%>
<%-- 	             :optionData2="<%=issueList %>" --%>
	
<!-- <vue-div> -->
<!--     <my-component1></my-component1> -->
<!--     <my-component2></my-component2> -->
<!-- </vue-div> -->
	<script src="<c:url value='/js/wwps/monitor/vue-dashboard3.js'/>"></script>
	
	
	
	<%-- 
	<div class="box6 last_mr" style="height: 360px;">
		<header class="title">사전알람</header>
		<div class="chart">
			<table class="detail_table">
				<tr>
					<th class="tc">구분</th>
					<th class="tc">건수</th>
				</tr>
				<tr>
					<td class="head1">검수미통보</td>
					<td class="tr"><div id="alarm07">0</div></td>
				</tr>
				<tr>
					<td class="head1">대금미지급</td>
					<td class="tr"><div id="alarm09">0</div></td>
				</tr>
				<tr style="background-color: #FFF0F5">
					<td class="head1">합계</td>
					<td class="tr"><div id="alarmTotal">0</div></td>
				</tr>
			</table>
		</div>
	</div>
	<div class="box4" id="divBox2">
		<header class="title">
			월별 항목별 비교 <select name="slChangeValue" id="slChangeValue2"
				class="second" style="width: 120px;" multiple="multiple">
				<c:forEach var="obj" items="${searchData.issueList}"
					varStatus="loopCount">
					<c:if test="${obj.code ne '07' and obj.code ne '09'}">
						<option value="${obj.code}">${obj.koLabel}</option>
					</c:if>
				</c:forEach>
			</select> <select name="slChangeChart" id="slChangeChart2" style="width: 60px">
				<option value="bar1" selected>막대</option>
				<option value="line">꺽은선</option>
			</select>
		</header>
		<div class="chart" id="graph2"></div>
	</div>
	<div class="box2" id="divBox3">
		<header class="title">
			월별미완료 <select name="slChangeChart" id="slChangeChart3"
				style="width: 60px">
				<option value="bar2" selected>막대</option>
				<option value="line">꺽은선</option>
			</select>
		</header>
		<div class="chart" id="graph3"></div>
	</div>
	<div class="box2 last_mr" id="divBox4">
		<header class="title">
			월별 확인대상 발생 <select name="slChangeChart" id="slChangeChart4"
				style="width: 60px">
				<option value="bar1">막대</option>
				<option value="line">꺽은선</option>
			</select>
		</header>
		<div class="chart" id="graph4"></div>
	</div>
	<div class="box2" id="divBox5">
		<header class="title">
			월별 확인결과 및 보상지급 <select name="slChangeChart" id="slChangeChart5"
				style="width: 60px">
				<option value="bar1">막대</option>
				<option value="line">꺽은선</option>
			</select>
		</header>
		<div class="chart" id="graph5"></div>
	</div>
	<div class="box2 last_mr" id="divBox6">
		<header class="title">
			System별 확인대상 건수 <select name="slChangeChart" id="slChangeChart6"
				style="width: 60px">
				<option value="bar1">막대</option>
				<option value="line">꺽은선</option>
			</select>
		</header>
		<div class="chart" id="graph6"></div>
	</div>
	<div class="box2" id="divBox7">
		<header class="title">
			사업부별 확인대상 건수 <select name="slChangeChart" id="slChangeChart7"
				style="width: 60px">
				<option value="bar1">막대</option>
				<option value="line">꺽은선</option>
			</select>
		</header>
		<div class="chart" id="graph7"></div>
	</div>
	<div class="box2 last_mr" id="divBox8">
		<header class="title">
			부서별 확인대상 건수 <select name="slChangeValue" id="slChangeValue8"
				class="second" style="width: 120px;" multiple="multiple">
				<c:forEach var="obj" items="${deptList}" varStatus="loopCount">
					<option value="${obj.code}">${obj.koLabel}</option>
				</c:forEach>
			</select> <select name="slChangeChart" id="slChangeChart8" style="width: 60px">
				<option value="bar1">막대</option>
				<option value="line">꺽은선</option>
			</select>
		</header>
		<div class="chart" id="graph8"></div>
	</div>
	<div class="box2" id="divBox9">
		<header class="title">
			공정별 확인대상 건수 <select name="slChangeChart" id="slChangeChart9"
				style="width: 60px">
				<option value="bar1">막대</option>
				<option value="line">꺽은선</option>
			</select>
		</header>
		<div class="chart" id="graph9"></div>
	</div>
	<div class="box2 last_mr" id="divBox10">
		<header class="title">
			분임조별 확인대상 건수 <select name="slChangeChart" id="slChangeChart10"
				style="width: 60px">
				<option value="bar1">막대</option>
				<option value="line">꺽은선</option>
			</select>
		</header>
		<div class="chart" id="graph10"></div>
	</div>
	 --%>
</div>