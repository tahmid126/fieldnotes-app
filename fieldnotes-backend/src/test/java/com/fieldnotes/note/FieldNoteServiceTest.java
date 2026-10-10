package com.fieldnotes.note;

import com.fieldnotes.common.exception.ResourceNotFoundException;
import com.fieldnotes.customer.Customer;
import com.fieldnotes.note.dto.FieldNoteRequest;
import com.fieldnotes.note.dto.FieldNoteResponse;
import com.fieldnotes.site.Site;
import com.fieldnotes.site.SiteRepository;
import com.fieldnotes.user.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FieldNoteServiceTest {

    @Mock
    private FieldNoteRepository fieldNoteRepository;

    @Mock
    private SiteRepository siteRepository;

    @InjectMocks
    private FieldNoteService fieldNoteService;

    private User testUser;
    private Customer testCustomer;
    private Site testSite;
    private FieldNote testNote;
    private UUID noteId;
    private UUID siteId;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .id(UUID.randomUUID())
                .email("tech@powergrid.com")
                .name("Power Tech")
                .build();

        testCustomer = Customer.builder()
                .id(UUID.randomUUID())
                .name("National Power Grid")
                .user(testUser)
                .build();

        siteId = UUID.randomUUID();
        testSite = Site.builder()
                .id(siteId)
                .name("Siddhirganj Power Plant")
                .address("Narayanganj")
                .customer(testCustomer)
                .user(testUser)
                .deleted(false)
                .build();

        noteId = UUID.randomUUID();
        testNote = FieldNote.builder()
                .id(noteId)
                .title("Turbine Pressure Check")
                .description("Turbine 2 vibration within normal limits")
                .location("Hall 3")
                .latitude(23.6850)
                .longitude(90.5050)
                .noteDateTime(LocalDateTime.now())
                .status("COMPLETED")
                .site(testSite)
                .user(testUser)
                .deleted(false)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
    }

    @Test
    void createNote_WhenSiteValid_SavesAndReturnsNote() {
        FieldNoteRequest request = new FieldNoteRequest();
        request.setTitle("Turbine Pressure Check");
        request.setStatus("COMPLETED");
        request.setSiteId(siteId);

        when(siteRepository.findByIdAndUserIdAndDeletedFalse(siteId, testUser.getId()))
                .thenReturn(Optional.of(testSite));
        when(fieldNoteRepository.save(any(FieldNote.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        FieldNoteResponse response = fieldNoteService.createNote(request, testUser);

        assertNotNull(response);
        assertEquals("Turbine Pressure Check", response.getTitle());
        assertEquals("COMPLETED", response.getStatus());
        assertEquals(siteId, response.getSiteId());
        assertEquals("Siddhirganj Power Plant", response.getSiteName());
        verify(fieldNoteRepository, times(1)).save(any(FieldNote.class));
    }

    @Test
    void createNote_WhenSiteNotFound_ThrowsException() {
        FieldNoteRequest request = new FieldNoteRequest();
        request.setTitle("Transformer Oil Test");
        request.setStatus("DRAFT");
        request.setSiteId(siteId);

        when(siteRepository.findByIdAndUserIdAndDeletedFalse(siteId, testUser.getId()))
                .thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> fieldNoteService.createNote(request, testUser));
        verify(fieldNoteRepository, never()).save(any(FieldNote.class));
    }

    @Test
    void getNotes_WithSearchQuery_CallsSearchAndFilterNotes() {
        when(fieldNoteRepository.searchAndFilterNotes(eq(testUser.getId()), isNull(), isNull(), eq("Turbine")))
                .thenReturn(List.of(testNote));

        List<FieldNoteResponse> results = fieldNoteService.getNotes(testUser, null, null, "Turbine");

        assertEquals(1, results.size());
        assertEquals("Turbine Pressure Check", results.get(0).getTitle());
    }

    @Test
    void deleteNote_SetsDeletedTrue() {
        when(fieldNoteRepository.findByIdAndUserIdAndDeletedFalse(noteId, testUser.getId()))
                .thenReturn(Optional.of(testNote));

        fieldNoteService.deleteNote(noteId, testUser);

        assertTrue(testNote.isDeleted());
        verify(fieldNoteRepository, times(1)).save(testNote);
    }
}
