"""
Refactored to make env-related part a module
""" 

PROD_ENVS = [ 'ech3', 'ela4' ]


class Env:
  def __init__(self, name):
    self.name = name

  def get_ccs_host(self):
    if self.name == 'stg' or self.name == 'beta':
      return 'esv4-be05.stg'
    elif self.name == 'ech3':
      return 'ech3-cfg02.prod'
    elif self.name == 'ela4':
      return 'ela4-glu02.prod'
    elif self.name == 'ei1':
      return 'esv4-be29.corp'
    elif self.name == 'ei3':
      return 'esv4-be44.corp'
    else:
      return None

  def check_envname_given(self):
    if self.name == 'stg' \
        or self.name == 'beta' \
        or self.name == 'ech3' \
        or self.name == 'ela4' \
        or self.name == 'ei1' \
        or self.name == 'ei3' \
      :
      pass
    else:
      print "ERROR: The environment name you provided ", self.name, " is invalid!"
      sys.exit(1)

  def get_ccs_dir_root(self):
    if self.name == 'stg':
      return '/export/content/repository/STG-ALPHA'
    elif self.name == 'beta':
      return '/export/content/repository/STG-BETA' 
    elif self.name == 'ech3':
      return '/export/content/master_repository/PROD-ECH3'
    elif self.name == 'ela4':
      return '/export/content/master_repository/PROD-ELA4'
    elif self.name == 'ei1':
      return '/export/content/repository/EI1'
    elif self.name == 'ei3':
      return '/export/content/repository/EI3'
    else:
      return None

  def get_fabric_name(self):
    if self.name == 'stg':
      return 'STG-ALPHA'
    elif self.name == 'beta':
      return 'STG-BETA' 
    elif self.name == 'ech3':
      return 'PROD-ECH3'
    elif self.name == 'ela4':
      return 'PROD-ELA4'
    elif self.name == 'ei1':
      return 'EI1'
    elif self.name == 'ei3':
      return 'EI3'
    else:
      return None


  def get_app_conf_base_uri(self):
    if self.name == 'stg':
      return 'http://esv4-be05.stg:10093/configuration/get/STG-ALPHA'
    elif self.name == 'beta':
      return 'http://esv4-be05.stg:10093/configuration/get/STG-BETA'
    elif self.name == 'ech3':
      return 'http://ech3-cfg-vip-a.prod:10093/configuration/get/PROD-ECH3'
    elif self.name == 'ela4':
      return 'http://ela4-cfg-vip-z.prod.foobar.com:10093/configuration/get/PROD-ELA4'
    elif self.name == 'ei1':
      return 'http://esv4-be29.corp:10093/configuration/get/EI1'
    elif self.name == 'ei3':
      return 'http://esv4-be44.corp:10093/configuration/get/EI3'
    else:
      return None

  def is_prod_env(self):
    prod_env_indicator = False
    if self.name in PROD_ENVS:
      prod_env_indicator =  True
    else:
      prod_env_indicator =  False
    return prod_env_indicator

def test():
    env = Env('ech3')
    print env.get_ccs_dir_root()
    if env.is_prod_env():
      print 'yes, i am prod env'
    else:
      print 'no, i am not prod env'

if __name__ == '__main__':
    test()

