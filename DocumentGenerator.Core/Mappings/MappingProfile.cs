using System.IO;
using AutoMapper;
using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Core.Entities;

namespace DocumentGenerator.Core.Mappings
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            CreateMap<Template, TemplateDto>();
            CreateMap<CreateTemplateDto, Template>();
            CreateMap<UpdateTemplateDto, Template>()
                .ForAllMembers(opts => opts.Condition((src, dest, srcMember) => srcMember != null));

            CreateMap<Document, DocumentDto>()
                .ForMember(dest => dest.FileName, opt => opt.MapFrom(src => Path.GetFileName(src.StoragePath)));
        }
    }
}
