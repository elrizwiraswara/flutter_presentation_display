package com.elriztechnology.flutter_presentation_display

import com.google.gson.annotations.SerializedName

data class DisplayModel(
    @SerializedName("displayId")
    val displayId: Int,
    
    @SerializedName("flags")
    val flags: Int,
    
    @SerializedName("rotation")
    val rotation: Int,
    
    @SerializedName("name")
    val name: String
)