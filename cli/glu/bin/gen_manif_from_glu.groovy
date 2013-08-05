#!/usr/bin/env groovy

/*

lwang: do parsing with groovy

*/


def cli = new CliBuilder()
cli.with {
  usage: 'Self'
  h longOpt:'help', 'usage information'
  e longOpt:'env', 'environment needed, e.g., beta, ech3, stg, ei', args:1
}

def opt = cli.parse(args)
if ( args.length == 0 ) {
  cli.usage()
  return
}
if (opt.h ) {
  cli.usage()
  return
}

if ( opt.e ) {
  env = opt.e
}

def topo_root_dir = "/export/content/http/i001/htdocs/cm/glu/topologies"
//println topo_root_dir

def env_dir = ""

switch( env ) {
  case 'beta':
    env_dir = "STG-BETA"
    break
  case 'stg':
    env_dir = "STG-ALPHA"
    break
  case 'ech3':
    env_dir = "PROD-ECH3"
    break
  case 'ei':
    env_dir = "EI1"
    break
  default: 
    cli.usage()
    return
}

//env_dir = "STG-BETA"

def dir_path  =  topo_root_dir+"/"+env_dir

def all_xml_files = []

//new File(topo_root_dir+"/"+env_dir).eachFileMatch(/.*.xml/) { file ->  
new File(dir_path).eachFileMatch(~/.*.xml/) { file ->  
//  println file.getName()  
  all_xml_files.add(file.getName())
  
}  


//println all_xml_files

all_xml_files.each { file ->
  def abs_path_to_file = dir_path + "/" + file
//  println abs_path_to_file
  parse_xml_file( abs_path_to_file )
}


def parse_xml_file( file) {

//  println "in func: " + file

  def topo = new XmlParser().parse( file )
  print topo.container['@name'][0]
  print "\t"
  
/*
  def entries = topo.container.entry
  for ( e in entries ) {
    println e['@host']
  }
*/

  def machines = []
  def containers = topo.container
  for ( ct in containers ) {
    def clusters = ct.cluster
    if ( clusters.size() != 0 ) {
      for ( cl in clusters ) {
        def entries = cl.entry
        for ( e in entries ) {
//          println e['@host']
          def h = e['@host']
          machines.add( h )
        }
      }
    }
    else {
      def entries = ct.entry
      for ( e in entries ) {
//        println e['@host']
        def h = e['@host']
        machines.add( h )
      }
    }
  }

  println  machines.join(' ')

/*
  def clusters = topo.container.cluster
  def entries2 = topo.container.cluster.entry
*/

//  println "container = ${root.container.attribute("name")}"
/*
  langs.language.each{
    println it.text()
  }
*/
  

}


System.exit(0)


