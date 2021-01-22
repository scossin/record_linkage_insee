# Training and test set data

## Filenames
* training set (containing the validation set): training_set17082020.tsv
* test set: test_set17082020.tsv

file separator: tabulation (\t)  
missing value: NA

## How these datasets were created ?
Each row corresponds to a pairwise comparison between a hospital record and a death certificate. True matches have target = 1 whereas false matches have target = 0. 

## Variable description

Each variable is a feature (except Target and NIP). 
Variable name (english translation): description

### last names:
* f_nom_osa (last_name_osa): last names comparison with optimal string alignment
* f_nom_lv (last_name_lv):  last names comparison with Levenshtein distance
* f_nom_dl (last_name_dl): last names comparison with Damerau-Levenshtein distance
* f_nom_hamming	(last_name_hamming): last names comparison with Hamming distance
* f_nom_lcs	(last_name_lcs): last names comparison with longest common subsequence distance
* f_nom_qgram (last_name_qgram): last names comparison with qgram distance
* f_nom_cosine (last_name_cosine): last names comparison with cosine distance
* f_nom_jaccard (last_name_jaccard): last names comparison with Jaccard distance
* f_nom_soundex	(last_name_soundex): last names comparison with Soundex distance
* f_nom_jw (last_name_jw): last names comparison with Jaro distance
* f_nom_jarowinkler (last_name_jarowinkler): last names comparison with Jaro-Winkler distance
* f_freq_nom (last_name_frequency): last name frequency of the hospital record in the French death master file

### first names:
* f_prenom_osa (last_name_osa): first names comparison with optimal string alignment
* f_prenom_lv (last_name_lv):  first names comparison with Levenshtein distance
* f_prenom_dl (last_name_dl): first names comparison with Damerau-Levenshtein distance
* f_prenom_hamming	(last_name_hamming): first names comparison with Hamming distance
* f_prenom_lcs	(last_name_lcs): first names comparison with longest common subsequence distance
* f_prenom_qgram (last_name_qgram): first names comparison with qgram distance
* f_prenom_cosine (last_name_cosine): first names comparison with cosine distance
* f_prenom_jaccard (last_name_jaccard): first names comparison with Jaccard distance
* f_prenom_soundex	(last_name_soundex): first names comparison with Soundex distance
* f_prenom_jw (last_name_jw): first names comparison with Jaro distance
* f_prenom_jarowinkler (last_name_jarowinkler): first names comparison with Jaro-Winkler distance
* f_freq_prenom (last_name_frequency): last name frequency of the hospital record in the French death master file

### sex
* f_sexe (sex): binary feature (1 if the values are the same, 0 otherwise)

### birth date
* f_date_naissance (birth_date_match): binary feature (1 if the values are the same, 0 otherwise)	
* f_annee_naissance	(birth_year_difference): integer, years comparison. Example: 1950 - 1936
* f_mois_naissance (birth_month_difference): integer, months comparison. Example: 12 - 5	
* f_jour_naissance (birth_day_difference): integer, days comparison. Example: 15 - 9

### birth location
* f_departnaissance (birth_department_code_match): binary feature (1 if the values are the same, 0 otherwise)
death_post_code): binary feature (1 if the values are the same, 0 otherwise)		
* f_paysNaissance (birth_location_country_match): binary feature (1 if the values are the same, 0 otherwise)	
* f_birthPlaceCode (birth_location_postal_code_match): binary feature (1 if the values are the same, 0 otherwise)
* f_birthPlaceName (birth_location_city_match): binary feature (1 if the values are the same, 0 otherwise)
* f_sameRegionNaissance	(birth_location_region_match): binary feature (1 if the values are the same, 0 otherwise)

### last visit date and death date
* f_diff_death_visit30 (hospital_visit_30_days_after_
death): binary feature, time difference between hospital record's last visit date and death certificate's death date > 30 days
* f_diff_death_visit180	(hospital_visit_180_days_after_
death): binary feature, time difference between hospital record's last visit date and death certificate's death date > 180 days
* f_diff_death_visit365	(hospital_visit_365_days_after_
death): binary feature, time difference between hospital record's last visit date and death certificate's death date > 365 days

### address 
* f_sameDepHabitDeath (address_postal_code_match_
death_post_code): binary feature (1 if the values are the same, 0 otherwise)		
* f_sameRegionHabitDeath (address_region_match_death_
region): binary feature (1 if the values are the same, 0 otherwise)	
* NIP: hospital record identifier. Each hospital record identifier in the training and test set is linked to a correct death certificate (a true match, target=1) and a wrong death certificate (false match, target=1). The same NIP in the training and test set doesn't mean it's the same hospital record: it's a fictive number that was generated after the creation of the test and training set. Don't use it in a machine learning model.  
* f_score: ElasticSearch score value	
* target: 1 if true match, 0 if false match

## Missing data

Missing data happen if either a hospital record or a death certificate has a missing field value. Thus, comparison is impossible and the feature value is NA. 


