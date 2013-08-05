import scala.util.matching.Regex
import collection.mutable.HashMap
import collection.immutable.TreeMap


val fname = "foo.txt"
//val lines = scala.io.Source.fromFile(fname).mkString
val lines = scala.io.Source.fromFile(fname).getLines

val h = new HashMap[String, Int]

val pattern = new Regex("""(.*)\s+(\d+)""", "str", "num")

for ( line  <- lines )  {
  val res = pattern.findFirstMatchIn(line).get
  
//  println(res.group("str") +", " + res.group("num"))
  val k = res.group("str")
  val v =  res.group("num").toInt
  if ( h.contains(k) ) {
    h(k) += v
  }
  else {
    h(k) = v
  }
}


val h_sorted = TreeMap(h.toSeq:_*)
for ( (k,v) <- h_sorted ) 
  println( k + "\t" + v)


/////////////////////////////////
/*
val pattern = new Regex("""(\w*) (\w*)""", "firstName", "lastName");
      val result = pattern.findFirstMatchIn("James Bond").get;
      println(result.group("lastName") + ", " + result.group("firstName"));
*/

