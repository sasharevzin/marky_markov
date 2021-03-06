#!/usr/bin/env ruby -i
#A Markov Chain generator.

require_relative 'marky_markov/persistent_dictionary'
require_relative 'marky_markov/markov_sentence_generator'

# @version = 0.3.5
# @author Matt Furden
# Module containing TemporaryDictionary and Dictionary for creation of
# Markov Chain Dictionaries and generating sentences from those dictionaries.
module MarkyMarkov
  VERSION = '0.3.5'

  class TemporaryDictionary
    # Create a new Temporary Markov Chain Dictionary and sentence generator for use.
    # Depth defaults to two words but can be set to any number between 1 and 9.
    #
    # @example Create a new Temporary Dictionary.
    #   markov = MarkyMarkov::TemporaryDictionary.new
    # @example Create a three word Temporary Dictionary.
    #   markov = MarkyMarkov::TemporaryDictionary.new(3)
    # @param [Int] depth Optional dictionary depth. Defaults to 2.
    # @return [Object] a MarkyMarkov::TemporaryDictionary object`.
    def initialize(depth=2)
      @dictionary = MarkovDictionary.new(depth)
      @sentence = MarkovSentenceGenerator.new(@dictionary)
    end

    # Returns the MarkovDictionary objects dictionary hash.
    # @return [Hash] the MarkovDictionary hash.
    def dictionary
      @dictionary.dictionary
    end

    # Parses a given file and adds the sentences it contains to the current dictionary.
    #
    # @example Open a text file and add its contents to the dictionary.
    #   markov.parse_file "text.txt"
    # @param [File] location the file you want to add to the dictionary.
    def parse_file(location)
      @dictionary.parse_source(location, true)
    end

    # Parses a given string and adds them to the current dictionary.
    #
    # @example Add a string to the dictionary.
    #   markov.parse_string "I could really go for some Chicken Makhani."
    # @param [String] string the sentence you want to add to the dictionary.
    def parse_string(string)
      @dictionary.parse_source(string, false)
    end

    # Generates a sentence/sentences of n words using the dictionary generated via
    # parse_string or parse_file.
    #
    # @example Generate a 40 word long string of words.
    #   markov.generate_n_words(40)
    # @example Generate a 10 word long string of words with method_missing.
    #   markov.generate_10_words
    # @param [Int] wordcount the number of words you want generated.
    # @return [String] the sentence generated by the dictionary.
    def generate_n_words(wordcount, seed = nil)
      @sentence.generate(wordcount, seed)
    end

    # Generates n sentences using the dictionary generated via
    # parse_string or parse_file. A sentence is defined as beginning with a
    # capitalized word and ending with either a . ! or ?
    #
    # @since 0.2.0
    # @example Generate three sentences.
    #   markov.generate_n_sentences(3)
    # @example Generate six sentences with method_missing.
    #   markov.generate_6_sentences
    # @param [Int] wordcount the number of sentences you want generated.
    # @return [String] the sentences generated by the dictionary.
    def generate_n_sentences(sentencecount, seed = nil)
      @sentence.generate_sentence(sentencecount, seed)
    end

    # Dynamically call generate_n_words or generate_n_sentences
    # if an Int is substituted for the n in the method call.
    #
    # @since 0.1.4
    # @example Generate a 40 and a 1 word long string of words.
    #   markov.generate_40_words
    #   markov.generate_1_word
    # @example Generate 2 sentences
    #   markov.generate_2_sentences
    # @return [String] the sentence generated by the dictionary.
    def method_missing(method_sym, *args, &block)
      if method_sym.to_s =~ /^generate_(\d*)_word[s]*$/
        generate_n_words($1.to_i)
      elsif method_sym.to_s =~ /^generate_(\d*)_sentence[s]*$/
        generate_n_sentences($1.to_i)
      else
        super
      end
    end

    # @since 0.1.4
    # Modify respond_to_missing? to include generate_n_words and generate_n_sentences
    # method_missing implementation.
    def respond_to_missing?(method_sym, include_private)
      if method_sym.to_s =~ /^generate_(\d*)_word[s]*$/
        true
      elsif method_sym.to_s =~ /^generate_(\d*)_sentence[s]*$/
        true
      else
        super
      end
    end

    # Clears the temporary dictionary's hash, useful for keeping
    # the same dictionary object but removing the words it has learned.
    #
    # @example Clear the Dictionary hash.
    #   markov.clear!
    def clear!
      @dictionary.dictionary.clear
    end
  end

  class Dictionary < TemporaryDictionary
    # Open (or create if it doesn't exist) a Persistent Markov Chain Dictionary
    # and sentence generator for use. Optional dictionary depth may be supplied.
    #
    # @example Create a new Persistent Dictionary object.
    #   markov = MarkyMarkov::Dictionary.new("#{ENV["HOME"]}/markov_dictionary")
    # @example Create a new Persistent Dictionary object with a depth of 4.
    #   markov = MarkyMarkov::Dictionary.new('mmdict.mmd'. 4)
    # @param [File] location The location the dictionary file is/will be stored.
    # @param [Int] depth The depth of the dictionary. Defaults to 2.
    attr_reader :dictionarylocation
    def initialize(location, depth=2)
      @dictionarylocation = "#{location}.mmd"
      @dictionary = PersistentDictionary.new(@dictionarylocation, depth)
      @sentence = MarkovSentenceGenerator.new(@dictionary)
    end

    # Save the Persistent Dictionary file into JSON format for later use.
    #
    # @example Save the dictionary to disk.
    #   markov.save_dictionary!
    def save_dictionary!
      @dictionary.save_dictionary!
    end

    # Takes a dictionary location/name and deletes it from the file-system.
    # Alternatively, pass in a MarkyMarkov::Dictionary object in
    # directly and it will delete that objects dictionary from disk.
    #
    # @note To ensure that someone doesn't pass in something that shouldn't
    # be deleted by accident, the filetype .mmd is added to the end of the
    # supplied argument, so do not include the extension when calling the method.
    #
    # @example Delete the dictionary located at '~/markov_dictionary.mmd'
    #   MarkyMarkov::Dictionary.delete_dictionary!("#{ENV["HOME"]}/markov_dictionary")
    # @example Delete the dictionary of the object 'markov'
    #   MarkyMarkov::Dictionary.delete_dictionary!(markov)
    # @param [String/Object] location location/name of the dictionary file to be deleted.
    def self.delete_dictionary!(location)
      location += ".mmd" if location.class == String
      PersistentDictionary.delete_dictionary!(location)
    end
  end
end
