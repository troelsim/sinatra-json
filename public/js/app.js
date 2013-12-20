App = Ember.Application.create({LOG_TRANSITIONS: true, LOG_TRANSITIONS_INTERNAL: true});


// Router

App.Router.map(function(){
	this.resource('companies',function(){
		this.resource('company', {path: ':company_id'}, function(){
			this.resource('owners', {path: '/owners'}, function(){
				this.resource('owner', {path: ':owner_id'});
			});
		});
	});
});

// Model

App.Company = DS.Model.extend({
	name: DS.attr('string'),
	email: DS.attr('string'),
	city: DS.attr('string'),
	country: DS.attr('string'),
	address: DS.attr('string'),
	phone: DS.attr('string'),
	owners: DS.hasMany('owner',{async:true})
});

App.Owner = DS.Model.extend({
	name: DS.attr('string'),
	passport: DS.attr('string'),
	company_id: DS.belongsTo('company'),
	passport_file: DS.attr('string')
});


/* ----------
   | Routes |
   ---------- */

// Front page
App.IndexRoute = Ember.Route.extend({});

// List of Companies
App.CompaniesRoute = Ember.Route.extend({
	model: function(){
		return this.store.find('company'); // Find all companies
	}
});

// Company Details
App.CompanyIndexRoute = Ember.Route.extend({
	model: function(){
		return this.modelFor('company'); // Find company
	}
});

// List of company owners
App.OwnersRoute = Ember.Route.extend({
	model: function(){
		return this.modelFor('company').get('owners'); // Find owners of company
	}
});

// Owner Details
App.OwnerRoute = Ember.Route.extend({
});



/* ---------------
   | Controllers |
   --------------- */

App.CompanyController = Ember.ObjectController.extend({
	actions: {
		save: function(){
			$('#company_save_button').button('loading');
			this.get('model').save().then(function(){
				$('#company_save_button').button('reset');
			});
		},
		deleteCompany: function(){
			if(window.confirm("Delete?")){
				this.get('content').deleteRecord();
				this.get('model').get('owners').forEach(function(owner){
					owner.deleteRecord();
				});
				this.get('model').save();
				this.get('target.router').transitionTo('companies.index');
			}
		}
	}
});

App.CompaniesController = Ember.ArrayController.extend({
	actions: {
		addCompany: function(){
			var company = this.get('store').createRecord('company');
			this.get('target.router').transitionTo('company.index',company);
		}
	}
});

App.OwnerController = Ember.ObjectController.extend({
	needs : ['company'], // So that we can access company information from the actions
	companyBinding: 'controllers.company', // So that the company record is updated when we update its owners
	actions: {
		save: function(){
			$('#owner_save_button').button('loading');
			var company = this.get('controllers.company').get('model');
			var owner = this.get('model');
			company.save().then(function(){ // Save company so that it gets an id if it's new
				owner.save().then(function(){ // Save the owners using that id
					company.save()
					$('#owner_save_button').button('reset');
					console.log("prps");
					console.log(this.get('id'));
				});
			});
		},
		deleteOwner: function(){
			if(window.confirm("Delete Owner?")){
				this.get('content').deleteRecord();
				this.get('model').save();
			}
		}
	}
});

App.OwnersController = Ember.ArrayController.extend({
	companyBinding: 'controllers.company', // So that the company record is updated when we update its owners
	needs : ['company'], // So that we can access company information from the actions
	actions: {
		addOwner: function(){
			var company = this.get('controllers.company');
			var owner = this.get('store').createRecord('owner', {companyId: company.get('model')});
			company.get('owners').addObject(owner);
			this.get('target.router').transitionTo('owner',owner);
		}
	}
});


/* |--------
   | Views |
   --------- */

App.FileView = Ember.View.extend({
	tagName: 'input',
	attributeBindings: ['type', 'id'],
	type: 'file',
	change: function(ev){
		view=this;
		reader = new FileReader();
		reader.onload = function(ev){
			view.set('file',ev.target.result);
		}
		reader.readAsDataURL(ev.target.files[0]);
	}
})
