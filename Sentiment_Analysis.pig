start-all.sh
pig -x local
--Load the tweets file
tweets = load 'sentiment/tweetsp' using PigStorage('\t') as (id:long,timestamp:chararray,tweet_count:int,text:chararray,screen_name:chararray,followers_count:chararray,time_zone:chararray);
dump tweets;
--Load the dictionary file, which contains the list of positive and negative words
dictionary = load 'sentiment/dictionary.tsv' using PigStorage('\t') as (type:chararray,length:int,word:chararray,pos:chararray,stemmed:chararray,polarity:chararray);
dump dictionary;
--tsv - Tab separated values
--csv - Comma separated values
--Load the timezone file, which contains the country name to time zone mapping
timezonemap = load 'sentiment/time_zone_map.tsv' using PigStorage('\t') as (time_zone:chararray,country:chararray,notes:chararray);
dump timezonemap;
--First we will tokenize the tweets into several words and flatten it
twords = foreach tweets generate id,FLATTEN(TOKENIZE(text)) as word;
dump twords;
--FLATTEN:- It is actually an operator that changes the structure of tuples and bags in a way
*/TOKENIZE:- Function of Pig Latin is used to slpit a string (which contains a group of words) in a single tuple and returns a bag which containsthe output of the split operation./*
tsentiment = join twords by word left outer, dictionary by word using 'replicated';
dump tsentiment;
--REPLICATTED:- In tho=is type of join the large relation is followed by one or more small relations i.e. removw dulicates
--Classify each word as either positive or negative word
wscore = foreach tsentiment generate twords::id as id, (CASE dictionary::polarity WHEN 'positive' THEN 1 WHEN 'negative' THEN -1 else 0 END) as score;
dump wscore;
--Group all word sentiments by each tweet(how many positive or negative words)
tgroup = group wscore by id;
dump tgroup;
--sum the sentiments scores for each tweets
tscore = foreach tgroup generate group as id, SUM(wscore.score) as final;
dump tscore;
--join time zone data with tweets using replicated
tweetstz = join tweets by time_zone left outer, timezonemap by time_zone using 'replicated';
dump tweetstz;
--generate data with tweets id and time zone as country
tcountry = foreach tweetstz generate tweets::id as id, timezonemap::country as country;
dump tcountry;
--each tweet is mapped with the country
tcomplete = join tscore by id left outer, tcountry by id;
dump tcomplete;
--classify each tweet as either positive or negative tweet
tclassify = foreach tcomplete generate tscore::id as id, tcountry::country as country, ((tscore::final>0) ? 1 : 0 ) as positive, ((tscore::final<0) ? 1 : 0 ) as negative;
dump tclassify;
--group the tweets by country
groupByCountries = group tclassify by country;
dump groupByCountries;
--find out how many positive and negative tweets per each country
sentimentByCountries = foreach groupByCountries generate group, SUM (tclassify.positive), SUM(tclassify.negative);
dump sentimentByCountries;
--write the final output
store sentimentByCountries into '/home/hadoop/Desktop/result';
quit
cat result/part-r-00000;
