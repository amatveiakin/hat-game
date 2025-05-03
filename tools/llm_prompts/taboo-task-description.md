I would like to create a list of words for a taboo-like game in Russian. The goal of the game is to explain words to your partner. Each word comes with a list of taboo words. One should explain the word without using cognates of the original word or of the taboo words.

I already have a list of words to explain, now I need to generate taboo words for each of them. I would like to use some LLM API to generate the words.

Requirements:
* Generate about 10 taboo words per word for each of about 5000 words.
* The total budget for the API calls is $100. So probably one should use a small model and/or apply batching or other cost saving techniques.
* The taboo words should cover all areas that could make explaining the words easier. These could be synonyms, antonyms, hypernyms, hyponyms, meronyms, holonyms, or generally speaking any words that are related or could be often used together with the word, e.g. because they form a name of a movie, a song, a book, etc. I found the latter to be particularly to elicit. E.g. I'd say “green” is obviously a good taboo word for “mile” (because of the “Green Mile” movie), but in my experiments I seldom got suggestions like this even when explicitly asking to include words that form movie titles together.
* It would be nice to also get a sense of the quality of the generated taboo words: which of those are game changers because they block some of the very natural ways of explaining the original word thus making the task much more interesting, and which are just random associations.
* Another big part of the task is to make sure the list of taboo words does not contain cognates. Since it's already forbidden by the rules to use cognates of either the original word or the taboo words, it doesn't make sense to include cognates in the list of taboo words. This part also proved to be tricky, because I couldn't find a way to determine if two Russian words are cognates with a decent quality. Note that 100% quality is not required. But even reasonable quality turned out to be a problem. The way I see it, we can only recognize cognates with sophisticated language-aware dictionaries and/or algorithms. Doing non-language-aware string manipulations like finding longest common substrings seems like a dead end to me, because it's quite typical for Russian words to have short roots and long suffixes/prefixes, which could easily be longer than the root itself. And I haven't found such libraries. But maybe they still exist? Or maybe we could use LLMs here too?

I need to figure out the overall strategy for generating the taboo words with high quality/price ratio. Questions that I have in mind:
* Which LLM API to use?
* Should I generate taboo words for each word separately or batch several words together? And if batching is used, how should the words be grouped?
* Should I write a detailed request for generating the taboo words directly? Should I first try to get words in each category (synonyms, antonyms, related words, etc.) and then choose the best ones? Or refine the word list iteratively? Or something else maybe? Remember that given a fixed budget, more calls means we'll probably have to use smaller models.
* How should I filter out cognates?
* How should I evaluate the quality of the generated taboo words?
