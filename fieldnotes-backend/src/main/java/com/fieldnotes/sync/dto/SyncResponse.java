package com.fieldnotes.sync.dto;

import com.fieldnotes.customer.dto.CustomerResponse;
import com.fieldnotes.note.dto.FieldNoteResponse;
import com.fieldnotes.site.dto.SiteResponse;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SyncResponse {

    private LocalDateTime serverTimestamp;

    @Builder.Default
    private List<CustomerResponse> customers = new ArrayList<>();

    @Builder.Default
    private List<SiteResponse> sites = new ArrayList<>();

    @Builder.Default
    private List<FieldNoteResponse> notes = new ArrayList<>();
}
