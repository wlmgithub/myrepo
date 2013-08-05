
h = Hash.new

File.open('foo.txt').each { |line|
  line.chomp!
  next if line =~ /^$/
  if line =~ /(.*)\s+(.*)/
    k, v = $1, $2 
    if h.has_key?(k)
      h[k] += v.to_i
    else
      h[k] = v.to_i
    end
  end
}

#puts '*' * 80
h.each { |k,v|
  print  k, "\t",  v, "\n"
}
