from nltk.stem.snowball import SnowballStemmer
from nltk.tokenize import word_tokenize

stemmer = SnowballStemmer("russian")
text = "Лесник переделывает скворечники"
tokens = word_tokenize(text)
stemmed_words = [stemmer.stem(word) for word in tokens]
print(stemmed_words)


# import nltk
# from nltk.stem import WordNetLemmatizer
# from nltk.tokenize import word_tokenize

# nltk.download("omw-1.4")
# nltk.download("wordnet")

# lemmatizer = WordNetLemmatizer()
# text = "The lemmatized form of leaves is leaf"
# tokens = word_tokenize(text)
# lemmatized_words = [lemmatizer.lemmatize(word) for word in tokens]
# print(lemmatized_words)
