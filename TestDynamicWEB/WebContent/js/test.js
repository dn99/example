/**
 * 
 */
// register the component
    var test = Vue.component('treeselect', VueTreeselect.Treeselect)
		
    new Vue({
      el: '#app',
      disabled: false,
      data: {
        // define default value
        value: null,
        // define options
        options: [ {
          id: 'a',
          label: 'a',
          children: [ {
            id: 'aa',
            label: 'aa',
          }, {
            id: 'ab',
            label: 'ab',
          } ],
        }, {
          id: 'b',
          label: 'b',
        }, {
          id: 'c',
          label: 'c',
        } ],
      },
      methods: {
    	  closeHandler: function(event) {
        	  this.disabled = true;
          }
      },
    })