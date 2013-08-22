
  /**
   *  MapBox pane for basemap chooser
   */

  cdb.admin.MapboxBasemapChooserPane = cdb.admin.BasemapChooserPane.extend({
    className: "basemap-pane",

    initialize: function() {
      this.template = this.options.template || cdb.templates.getTemplate('table/views/basemap_chooser/basemap_chooser_pane');
      this.render();
    },

    render: function() {
      this.$el.html(this.template({
        placeholder: 'Insert your MapBox map URL or your MapBox map id',
        error: 'Your MapBox map URL or your MapBox map id is not valid.'
      }));
      return this;
    }
  });