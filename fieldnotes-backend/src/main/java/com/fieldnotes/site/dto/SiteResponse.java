package com.fieldnotes.site.dto;

import com.fieldnotes.site.Site;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SiteResponse {

    private UUID id;
    private String name;
    private String address;
    private UUID customerId;
    private String customerName;
    private boolean deleted;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static SiteResponse fromEntity(Site site) {
        return SiteResponse.builder()
                .id(site.getId())
                .name(site.getName())
                .address(site.getAddress())
                .customerId(site.getCustomer() != null ? site.getCustomer().getId() : null)
                .customerName(site.getCustomer() != null ? site.getCustomer().getName() : null)
                .deleted(site.isDeleted())
                .createdAt(site.getCreatedAt())
                .updatedAt(site.getUpdatedAt())
                .build();
    }
}
