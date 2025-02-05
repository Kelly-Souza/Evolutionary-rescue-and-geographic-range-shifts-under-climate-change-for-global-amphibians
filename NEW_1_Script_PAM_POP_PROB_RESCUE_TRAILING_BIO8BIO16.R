setwd("C:/Users/lets/Desktop/RESCUE/Test_final_2")
rm(list=ls())

bios_0k <- read.table("BIOS_modermPres_PAM_filtred.txt", h=T)
bios_ccsm60 <- read.table("BIOS_moderfut_ccsm_rcp60_PAM_filtred.txt", h=T)

t0<- bios_0k$bio8moderpres
t1<- bios_ccsm60$bio8moderfut_ccsm_rcp60
pluv0 <-bios_0k$bio16moderpres
pluv1 <-bios_ccsm60$bio16moderfut_ccsm_rcp60
coords <- bios_0k[,1:2]
write.table(coords,"coords.txt")
remove(bios_0k)
remove(bios_ccsm60)


sdsd <- read.table("SD_ajust_FST_pop4.txt", header = T)
colnames(sdsd)
sdsd <- sdsd [,c(2,6)]

#gen <- read.table("geracao.txt", h=F) #generations
#gen <- gen$V2
options(digits=3)
gen <- runif(1000, 40, 60)
min(gen)
max(gen)



PA1 <-read.table(file = "PAM_filtered_amphibian.txt" ,h=T)

coords <- PA1[, c(1,2)]
PA1 <- PA1[,-c(1,2)]
PAMS_NAMES <- colnames(PA1)

setwd("C:/Users/lets/Desktop/RESCUE/Test_final_2/Trailing_noexpand")
listaMatriz_Spp <- list.files(pattern = "Trailing")
length(listaMatriz_Spp)
PA_out <- matrix(NA, nrow = nrow(PA1), ncol = ncol(PA1)) 
NewPAM_rescue <- matrix(NA, nrow = nrow(PA1), ncol = ncol(PA1)) 

pb2 <- txtProgressBar(min=0, max= ncol(PA1), style = 3) 

for(k in 1:7193){
  setTxtProgressBar(pb2,k)
  
  setwd("C:/Users/lets/Desktop/RESCUE/Test_final_2/Trailing_noexpand")
  PA_inic <- read.table( file = paste( "matrizPA", PAMS_NAMES[k] ,"Trailing_noexpand.txt", sep = ""), h=T)#PAM das populacoes de cada trailing
  #PA_inic <- read.table( "matrizPAAcanthixalus_spinosusTrailing.txt", h=T)#PAM das populacoes de cada trailing
  
  PA <- as.matrix(PA_inic[,3:length(PA_inic)])
  remove(PA_inic) #release RAM memory
  
  out.pop <- numeric()
  colunas <- PA
  
  
  for(i in 1:ncol(PA)){
    range <- PA[,i]
    loc <- which(PA[,i]==1)
    mlat <-(sum(coords[,2]*range))/sum(range)
    mlong <-sum(coords[,1]*range)/sum(range)
    t0rg <- t0[which(range==1)]
    t1rg <- t1[which(range==1)]
    pk0 <- mean(t0[which(range==1)])
    pk1 <- mean(t1[which(range==1)])
    pk.shift <- pk1 - pk0
    
    
    pluv0rg <- pluv0[which(range==1)]
    pluv1rg <- pluv1[which(range==1)]
    pl0 <- mean(pluv0[which(range==1)])
    pl1 <- mean(pluv1[which(range==1)])
    pl.shift1 <- (pl1 - pl0)/pl1
    pl.shift <- ifelse(pl.shift1 == "NaN", yes = 0, no= pl.shift1)
    
    #deviation in geographical space 
    sd.rg1 <- sdsd[which(sdsd[,1] == colnames(PA1)[k]),2]
    sd.rg <- ifelse(pl.shift >= 0, yes = sd.rg1, no= (sd.rg1*(1+pl.shift)))
    
    #gen <- round(runif(1,40,50)) #generations
    
    
    #randomizations within each species
    #sFST <-numeric(length = 1000)
    #sd.imp <-numeric(length = 1000)
    hald <- numeric()
    #rescue <- numeric()
    rescue.P <- numeric()
    
    
    set.seed(0)
    for(j in 1:1000){
      h2 <-runif(n = 1, min = 0.20, max = 0.4)
      sd.geo <- sd.rg
      sd <- sd.geo
      vT = sd*sd
      vA = vT*h2
      vE <- vT-vA
      
      #ss <-50 #more or less like Schneideri... - sum(colSums(PA_out)==0) = 2369 (1001 erros)
      ss <-runif(1,40,60) # - sum(colSums(PA_out)==0) = 2090 (66 erros) 
      
      w2 <- (sd.rg*sd.rg)*ss*h2 
      Vs <- w2 + vE
      B <-runif(n = 1, min = 1.1, max = 1.25)
      #sd <-sqrt((1 - fst) * (sd.geo*sd.geo))# for means the FST is not necessary...
      
      if(B*sqrt(w2/(vA+Vs)) < 1){
        TB = 1.0001
      } else {
        TB <- B*sqrt(w2/(vA+Vs))
      }
      
      #Haldane
      hald[j] <- (abs(pk.shift))/sd.rg/gen[j]
      
      #Chevin plasticity
      b <- runif(n = 1, min = 0.01, max = 0.25)
      GT <- runif(n = 1, min = 1.5, max = 6)
      kp <- sqrt(((2*log(B)*(1/Vs))/GT)*((h2*vT)/(1 - b)))
      rescue.P[j] <- ifelse(test = hald[j] > kp, yes = 0, no = 1)
      
      
    }
    
    #Outputs
    
    #out.pop[i] <- mean(rescue.P)/ncol(PA)#n�o dividir por colunas
    out.pop[i] <- sum(rescue.P)/length(rescue.P)
    
    for (l in 1:nrow(colunas)){ 
      colunas[l,i] <- ifelse(test = colunas[l,i]==1 , yes = out.pop[i], no = 0)
    }
    
  }
  options(digits=3)
  setwd("C:/Users/lets/Desktop/RESCUE/Test_final_2/rescue_trailing")
  write.table( colunas, paste ("matrizPA", PAMS_NAMES[k] ,"Trailing_noexpand_prob_rescue.txt", sep = ""))
  
  PA3 <-rowSums(colunas)
  PA_out[,k] <- PA3 
  
}

colnames(PA_out) <- as.vector(colnames(PA1))
PA_out1 <- cbind(coords, PA_out)
setwd("C:/Users/lets/Desktop/RESCUE/Test_final_2")

write.table(PA_out1, "PAM_PROB_RESCUE_TRAILING.txt") 
write.table(PA_out, "PA_out.txt")

# setwd("C:/Users/lets/Desktop/RESCUE/Test_final_1/Trailing/")
#PA_inic1 <- read.table( file = paste( "matrizPA", PAMS_NAMES[k] ,"Trailing_noexpand.txt", sep = ""), h=T)#PAM das populacoes de cada trailing
#colunas <- PA_inic1[,-c(1:2)]
#setwd("C:/Users/lets/Desktop/RESCUE/Test_final_2/rescue_trailing/")
#write.table( colunas, paste ("matrizPA", PAMS_NAMES[k] ,"Trailing_prob_rescue.txt", sep = ""))

# 
# ##########################
# rm(list=ls())
# PAM1 <- read.table ("PAM_PROB_RESCUE_TRAILING.txt")
# coords <- PAM1[,c(1,2)]
# PAM1 <- PAM1[,-c(1,2)]
# 
# 
# 
# ########
# NewPAM_rescue <- matrix(0) 
# dim(NewPAM_rescue)
# PA_Prop_Rescue <- PAM1
# riq_PA_Prop_Rescue <- numeric()
# 
# for(i in 1:nrow(PAM1)){
#   
#   number_PA_Prop_Rescue [i] <- sum(PA_Prop_Rescue[i,]>0)
#   
# }
# 
# range(riq_PA_Prop_Rescue)
# 
# riq_prob <- cbind(coords,   number_PA_Prop_Rescue)
# write.table(riq_prob, "riq_prob_rescue.txt")
# 
# 
# result <- read.table("riq_prob_rescue.txt", h=T)
# 
# result1 <- cbind(result, PAM2_linha )
# colnames(result1) <- c("lat", "long", "range_prob", "sum_prob")
# 
# prob_media_rescue <- result1$sum_prob/result1$range_prob
# 
# result2 <- cbind(result1, prob_media_rescue )
# colnames(result2) <- c("lat", "long", "range_prob", "sum_prob", "prob_media_rescue")
# write.table(result2, "prob_media_rescue.txt")
# 
# (rowSums(PA_Prop_Rescue)/number_PA_Prop_Rescue)
# 
# remove(PAM_Rescue)
# 
# 
# dim(PA_Prop_Rescue)
# 
# 
# 
# 
# 
# ########
# PA_Prop_Rescue <- PA_out
# trailing <- read.table("PAM_trailing.txt")
# trailing <- trailing[,-c(1,2)]
# PAM_Prop_Rescue_trailing <- matrix(NA, ncol= ncol(PAM2), nrow=nrow(PAM2))
# for(i in 1:ncol(trailing)){
#   PAM_Prop_Rescue_trailing[,i] <-  ifelse(test = trailing[,i] == 1,
#                                           yes = PAM2[,i],
#                                           no = 0)
# }
# 
# write.table(PAM_Prop_Rescue_trailing,"PAM_Prop_Rescue_trailing.txt")
# 
# dim(PAM_Prop_Rescue_trailing)
# (rowSums(PA_MA_Prop_Rescue)/rowSums(PA_MA))
# 
# 
# 
# 
#
setwd("C:/Users/lets/Desktop/RESCUE/Test_final_2")
rm(list=ls())

PA_out <- read.table("PA_out.txt", h=T)
dim(PA_out)
head(PA_out[1:6,1:6])

PA4  <- ifelse(test = PA_out >= 0.95 , yes = 1, no = 0)
PA5 <- ifelse(test = PA_out > 0  & PA_out <= 0.05 , yes = 1, no = 0)
PA6 <- ifelse(test = PA_out > 0.05 , yes = 1, no = 0)

riqueza_PA4 <-rowSums(PA4)
riqueza_PA5 <-rowSums(PA5)
riqueza_PA6 <-rowSums(PA6)

PA_out2  <- ifelse(test = PA_out > 0 , yes = 1, no = 0)
riqueza_PA_out2 <-rowSums(PA_out2)

riquezas_trailing_rescue_Bio8_Bio16 <- cbind(coords, riqueza_PA4, riqueza_PA5, riqueza_PA6, riqueza_PA_out2)
colnames(riquezas_trailing_rescue_Bio8_Bio16) <- c("lat", "long", "riqmais095", "riqmenos005", "riqmais005", "riqtrailing")
write.table(riquezas_trailing_rescue_Bio8_Bio16, "riquezas_trailing_rescue_Bio8_Bio16.txt")

hist(riqueza_PA6)

colnames(PA_out)

colnames(PA6) <- colnames(PA_out)
PA_out6 <- cbind(coords, PA6)

write.table(PA_out4, "PAM_PROB_RESCUE_TRAILING_mais095.txt")
write.table(PA_out5, "PAM_PROB_RESCUE_TRAILING_menos005.txt")
write.table(PA_out6, "PAM_PROB_RESCUE_TRAILING_mais005.txt")
remove(PA6)
remove(PA_out6)

#############
library(raster)

riq <- read.table("riquezas_trailing_rescue_Bio8_Bio16.txt", h=T) 
head(riq)
todotrailing <- rasterFromXYZ(cbind(riq[,c(1,2,6)]))
plot(todotrailing)
mais95 <- rasterFromXYZ(cbind(riq[,c(1,2,3)]))
plot(mais95)
mais05 <- rasterFromXYZ(cbind(riq[,c(1,2,5)]))
plot(mais05)
menos05 <- rasterFromXYZ(cbind(riq[,c(1,2,4)]))
plot(menos05)

maior95 <- read.table("PAM_PROB_RESCUE_TRAILING_mais095.txt", h=T)
head(maior95[1:6,1:6])

sum(colSums(maior95[,-c(1:2)])>0)

###
maior005 <- read.table("PAM_PROB_RESCUE_TRAILING_mais005.txt", h=T)
head(maior005[1:6,1:6])

sum(colSums(maior005[,-c(1:2)])>0)


