#
# Cookbook:: metasploitable
# Attributes:: users
#



default[:users][:tyler] = { username: 'tyler',
                                  password: 'redacted',
                                  password_hash: '$6$n67I5.deJtxrC6qR$nFKbkISjdBZDJ1NW2c47zsSUPfeHdqr6rhDYy7SZVEENT8JrmXX6U5dQ8d2MizYpCMg9QBN2grtijnVuD1kDW/',
                                  ssh_keys: ''
                                  first_name: 'Tyler',
                                  last_name: 'Hydra',
                                  admin: true
                                  }

