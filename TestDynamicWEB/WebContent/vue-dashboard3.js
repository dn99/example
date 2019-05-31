var content = '<header class="title">{{ headTitle }}'
		+ '	<div v-if="option1">'
		+ '		<select name="slChangeValue" id="slChangeValue2" class="second" style="width: 120px;" multiple="multiple">'
		+ '		<c:forEach var="obj" :items=optionData1 varStatus="loopCount">'
		+ '		<c:if test="${obj.code ne "07" and obj.code ne "09"}">'
		+ '			<option value="${obj.code}">${obj.koLabel}</option>'
		+ '		</c:if>'
		+ '		</c:forEach>'
		+ '	</select>'
		+ '	</div>'
		+ '	<select name="slChangeChart" id="slChangeChart" style="width: 60px">'
		+ '		<option value="chart" selected>챠트</option>'
		+ '		<option value="grid">표</option>' + '	</select>' + '</header>'
		+ '<div class="chart" id="graph"></div>';

var container = {
	template : '<header class="title">{{ headTitle }}</header>',
	// data : {
	// optionData1 : null,
	// optionData2 : null
	// },
	components : {
		'divOption1' : divOption1,
		'divOption2' : divOption2,
	},
	mounted : function() {
		console.log("optionData1 : " + this.optionData1);
	},
	methods : {
		setOption1 : function(value) {
			optionData1 = value;
		},
		getOption1 : function() {
			return optionData1;
		}
	},
	props : [ 'headTitle', 'option1', 'option2', 'optionData1', 'optionData2' ]
};

var divOption1 = {
	template : '<div v-view="option1"><select name="slChangeValue" id="slChangeValue" class="second" style="width: 120px;" multiple="multiple"></select></div>',
	// data : {
	// optionData1 : null,
	// optionData2 : null
	// },
	mounted : function() {
		console.log("divOption1 : " + this.optionData1);
	},
	methods : {
		setOption1 : function(value) {
			optionData1 = value;
		},
		getOption1 : function() {
			return optionData1;
		}
	},
	props : [ 'headTitle', 'option1', 'option2', 'optionData1', 'optionData2' ]
};

var divOption2 = {
	template : '<select name="slChangeChart" id="slChangeChart" style="width: 60px">'
			+ '		<option value="chart" selected>챠트</option>'
			+ '		<option value="grid">표</option></select>',
	// data : {
	// optionData1 : null,
	// optionData2 : null
	// },
	mounted : function() {
		console.log("divOption2 : " + this.optionData1);
	},
	methods : {
		setOption1 : function(value) {
			optionData1 = value;
		},
		getOption1 : function() {
			return optionData1;
		}
	},
	props : [ 'headTitle', 'option1', 'option2', 'optionData1', 'optionData2' ]
};

new Vue({
	el : '#divBox1',
	components : {
		'container' : container,
	},
	data : {
		headTitle : "월별 항목별 비교",
		className : "box5",
		option1 : true,
		option2 : false,
	},
	mounted : function() {
		console.log("headTitle : " + this.headTitle);
	},
	computed : computed,
	methods : methods,
});

var computed = {

};

var methods = {

};
