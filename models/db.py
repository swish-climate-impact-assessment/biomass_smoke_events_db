# -*- coding: utf-8 -*-

#########################################################################
## This scaffolding model makes your app work on Google App Engine too
## File is released under public domain and you can use without limitations
#########################################################################

## if SSL/HTTPS is properly configured and you want all HTTP requests to
## be redirected to HTTPS, uncomment the line below:
# request.requires_https()

if not request.env.web2py_runtime_gae:
    ## if NOT running on Google App Engine use SQLite or other DB
    db = DAL('sqlite://storage.sqlite',pool_size=1, fake_migrate_all = True, migrate=False)
    #db = DAL("postgres://user:password@localhost:5432/dbname", fake_migrate_all = True, migrate = False)
else:
    ## connect to Google BigTable (optional 'google:datastore://namespace')
    db = DAL('google:datastore')
    ## store sessions and tickets there
    session.connect(request, response, db=db)
    ## or store session in Memcache, Redis, etc.
    ## from gluon.contrib.memdb import MEMDB
    ## from google.appengine.api.memcache import Client
    ## session.connect(request, response, db = MEMDB(Client()))

## by default give a view/generic.extension to all actions from localhost
## none otherwise. a pattern can be 'controller/function.extension'
response.generic_patterns = ['*'] # if request.is_local else []
## (optional) optimize handling of static files
# response.optimize_css = 'concat,minify,inline'
# response.optimize_js = 'concat,minify,inline'
## (optional) static assets folder versioning
# response.static_version = '0.0.0'
#########################################################################
## Here is sample code if you need for
## - email capabilities
## - authentication (registration, login, logout, ... )
## - authorization (role based authorization)
## - services (xml, csv, json, xmlrpc, jsonrpc, amf, rss)
## - old style crud actions
## (more options discussed in gluon/tools.py)
#########################################################################

from gluon.tools import Auth, Crud, Service, PluginManager, prettydate
auth = Auth(db)
crud, service, plugins = Crud(db), Service(), PluginManager()

## create all tables needed by auth if not custom tables
auth.define_tables(username=False, signature=False)

## configure email
mail = auth.settings.mailer
mail.settings.server = 'logging' or 'smtp.gmail.com:587'
mail.settings.sender = 'you@gmail.com'
mail.settings.login = 'username:password'

## configure auth policy
auth.settings.registration_requires_verification = False
auth.settings.registration_requires_approval = False
auth.settings.reset_password_requires_verification = True

## if you need to use OpenID, Facebook, MySpace, Twitter, Linkedin, etc.
## register with janrain.com, write your domain:api_key in private/janrain.key
from gluon.contrib.login_methods.rpx_account import use_janrain
use_janrain(auth, filename='private/janrain.key')

#########################################################################
## Define your tables below (or better in another model file) for example
##
## >>> db.define_table('mytable',Field('myfield','string'))
##
## Fields can be 'string','text','password','integer','double','boolean'
##       'date','time','datetime','blob','upload', 'reference TABLENAME'
## There is an implicit 'id integer autoincrement' field
## Consult manual for more options, validators, etc.
##
## More API examples for controllers:
##
## >>> db.mytable.insert(myfield='value')
## >>> rows=db(db.mytable.myfield=='value').select(db.mytable.ALL)
## >>> for row in rows: print row.id, row.myfield
#########################################################################

## after defining tables, uncomment below to enable auditing
# auth.enable_record_versioning(db)
db.define_table(
    'biomass_smoke_reference',
    Field('source', 'string', comment='Compulsory. The source. Author or Organisation.'),
    Field('title', 'string', comment= 'Compulsory. Reference title.'),    
    Field('year', 'integer', comment = 'Compulsory. Publication year'),
    Field('credentials', 'string', comment='Type of source.', requires=IS_IN_SET(['other','government','internet','journal','media','modis hotspot','modis smoke','toms'])),
    Field('credentials_other', 'string', comment='What other type of source?'),
    Field('protocol_used', 'text', comment = XML(T('See this %s link. The protocol used to identify evidence of an event, for example Johnston2011 for the original method of searching all news, journals, reports and satellite data, or Salimi2016 if only satellite data where used.  The "Bare Minimum protocol" can be used if no air pollution data were analysed and there is just some reference available. Optionally leave this blank and it will be inserted on submission to the online master database.  Please also submit information on the protocol to the database manager.', A('protocol', _href=XML(URL('static','protocols.html', scheme=True, host=True)), _target='new2')))
          ),    
    Field('authors', 'string', comment= 'Author list.'),
    Field('volume', 'integer', comment = 'Journal volume.'), 
    Field('url', 'string', comment= 'Desirable. This can be URL, doi or weblink of any kind (and date accessed). Also you might want to add the folder location on your computer and the file name.'),
    Field('summary', 'text', comment= 'Short summary written by you.'),
    Field('abstract', 'text', comment= 'Executive summary copied from the journal/report abstract.'),
    Field('contributor', 'string', comment='The contributor of this reference information.'),    
    format = '%(source)s %(id)s' 
    )

db.biomass_smoke_reference.source.requires = IS_NOT_EMPTY()
db.biomass_smoke_reference.title.requires = IS_NOT_EMPTY()
db.biomass_smoke_reference.year.requires = IS_NOT_EMPTY()

db.define_table(
    'biomass_smoke_event',
    Field('biomass_smoke_reference_id', db.biomass_smoke_reference),
    Field('place', requires = IS_IN_SET(['Other','ALBANY','Albury','Bathurst','BUNBURY','BUSSELTON','Canberra','GERALDTON','Gosford','hobart','Illawarra','launceston','Newcastle','Melbourne','PERTH','Sydney East','Sydney West','Tamworth','Wagga Wagga','Wyong']), comment='The pre-determined study locations of the biomass smoke project.'),
    Field('place_other', 'string', comment='If you chose "other place" what is the name of this?'),        
    Field('event_type', requires = IS_IN_SET(['bushfire','dust','non-biomass, fire','non-biomass, non-fire','possible biomass','prescribed burn','woodsmoke']), comment = 'Compulsory. Select from list'),
    Field('min_date', 'date', comment='The first date of known event. Compulsory.'),
    Field('max_date', 'date', comment = 'The last date of known event. Optional'),
    Field('burn_area_ha', 'double', comment = 'The area burnt in hectares'),
    Field('met_conditions', 'text', comment = 'Free text notes about relevant meteorological conditions'),
    format = '%(place)s %(id)s' 
    )

db.biomass_smoke_event.min_date.requires = IS_NOT_EMPTY()
