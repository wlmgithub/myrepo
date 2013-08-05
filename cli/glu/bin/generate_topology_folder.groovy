import groovy.xml.MarkupBuilder

/**
 * Script (one time) to generate the topology folder from the old manifest
 * @author ypujante@foobar.com */
def cli = new CliBuilder(usage: 'groovy generate_topology_folder.groovy [-h]')
cli.h(longOpt: 'help', 'display help')
cli.f(longOpt: 'fabric', 'the name of the fabric', args:1, required: true)
cli.d(longOpt: 'directory', 'the name of manifest directory', args:1, required: true)
cli.o(longOpt: 'outputDirectory', 'the name of directory to create', args:1, required: true)

def options = cli.parse(args)
if(!options)
{
  return
}

if(options.h)
{
  cli.usage()
  return
}

def parseClusters(Reader reader)
{
  def clusters = [:]

  def root = new XmlSlurper().parse(reader)

  root.cluster.list().each {c ->
    def entries = []

    def clusterName = c['@name'].toString()

    // optional cluster app
    def clusterApp = c['@app'].toString()

    c.entry.list().each {e ->
      def entry = [
          host: e['@host'].toString(),
          app: e['@app'].toString() ?: clusterApp,
          instance: e['@instance'].toString() ?: 'i001'
      ]

      def cs = clusters[entry.app]
      if(!cs)
      {
        cs = [:]
        clusters[entry.app] = cs
      }

      def clusterEntries = cs[clusterName]
      if(!clusterEntries)
      {
        clusterEntries = []
        cs[clusterName] = clusterEntries
      }

      clusterEntries << entry
    }
  }

  return clusters
}

def fabric = options.f

def appmachines = new File(options.d as String, "manifest_${fabric}").readLines()
def clustersFile = new File(options.d as String, "clusters_${fabric}.xml")
def containers = [:]
new File(options.d as String, "container_mapping_${fabric}").eachLine { line ->
  def tokens = line.split(/\t/)
  containers[tokens[0]] = tokens[1]
}

def clusters = [:]
if(clustersFile.exists())
{
  clustersFile.withReader { clusters = parseClusters(it) }
}

def apps = [:]

appmachines.each { line ->
  def tokens = line.split(/( |\t)/)
  def appname = tokens[0]

  // for some apps, the names differ... use mapping file for this...
  if(containers[appname])
    appname = containers[appname]

  def hosts = new TreeSet()
  tokens[1..-1].each { token ->
    token = token.trim()
    if(token)
      hosts << token
  }

  apps[appname] = hosts
}

def outputDir = new File(options.o as String, "${fabric}")
outputDir.mkdirs()

apps.each { name, hosts ->
  def file = new File(outputDir, "${name}.xml")

  file.withWriter { Writer writer ->
    def builder = new MarkupBuilder(writer)
    builder.topology {
      container(name: name) {
        if(clusters[name])
        {
          clusters[name].each { clusterName, clusterEntries ->
            cluster(name: clusterName) {
              clusterEntries.each { clusterEntry ->
                entry(host: clusterEntry.host, instance: clusterEntry.instance)
              }
            }
          }
        }
        else
        {
          hosts.each { h ->
            entry(host: h)
          }
        }
      }
    }
  }
}

println "Created ${apps.size()} files in ${outputDir}"