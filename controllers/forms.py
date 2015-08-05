def manage_references():
    grid = SQLFORM.smartgrid(db.biomass_smoke_reference,linked_tables=['biomass_smoke_event'
                                                      ],
                             fields = [db.biomass_smoke_reference.id,
                                       db.biomass_smoke_reference.source,
                                       db.biomass_smoke_reference.credentials,
                                       db.biomass_smoke_reference.year,
                                       
                                       db.biomass_smoke_reference.title,
                                       db.biomass_smoke_event.place,
                                       db.biomass_smoke_event.min_date,
                                       db.biomass_smoke_event.event_type
                                       ],
                                       orderby = dict(id=db.biomass_smoke_reference.id, place=db.biomass_smoke_event.place),
                             user_signature=True,maxtextlength =50, csv=False, paginate=35)
    return dict(grid=grid)
def manage_events():
    grid = SQLFORM.smartgrid(db.biomass_smoke_event,linked_tables=['biomass_smoke_reference'
                                                      ],
                             fields = [db.biomass_smoke_event.id,
                                       db.biomass_smoke_event.place,
                                       db.biomass_smoke_event.min_date,
                                       db.biomass_smoke_event.event_type,
                                       db.biomass_smoke_event.biomass_smoke_reference_id,
                                       db.biomass_smoke_reference.id,
                                       db.biomass_smoke_reference.source,
                                       db.biomass_smoke_reference.credentials,
                                       db.biomass_smoke_reference.year,
                                       
                                       db.biomass_smoke_reference.title                                       
                                       ],
                                       orderby = dict(place=db.biomass_smoke_event.place, min_date=db.biomass_smoke_event.min_date),
                             user_signature=True,maxtextlength =50, csv=True, paginate=35)
    return dict(grid=grid)
